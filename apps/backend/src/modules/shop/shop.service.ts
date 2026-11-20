import { Injectable, Logger, BadRequestException, NotFoundException } from '@nestjs/common';
import { CultivationService } from '../cultivation/cultivation.service.js';
import { SupabaseService } from '../database/supabase.service.js';
import { DEFAULT_SHOP_ITEMS, ShopItem } from './shop-items.constants.js';

export interface UserInventoryItem {
  id: string;
  itemId: string;
  userId: string;
  name: string;
  category: string;
  quantity: number;
  effect: string;
  iconType: string;
  purchasedAt: string;
}

@Injectable()
export class ShopService {
  private readonly logger = new Logger(ShopService.name);
  private readonly inMemoryInventory = new Map<string, Map<string, UserInventoryItem>>();

  constructor(
    private readonly cultivationService: CultivationService,
    private readonly supabaseService: SupabaseService,
  ) {}

  getItems(): ShopItem[] {
    return DEFAULT_SHOP_ITEMS;
  }

  getItemById(itemId: string): ShopItem | undefined {
    return DEFAULT_SHOP_ITEMS.find((item) => item.id === itemId);
  }

  async getInventory(userId: string): Promise<UserInventoryItem[]> {
    const client = this.supabaseService.getClient();

    // 1. Thử lấy từ Supabase bảng user_inventory
    if (client) {
      try {
        const { data, error } = await client
          .from('user_inventory')
          .select('*')
          .eq('user_id', userId);

        if (!error && data && data.length > 0) {
          const itemsFromDb: UserInventoryItem[] = data
            .filter((row: any) => (row.quantity || 0) > 0)
            .map((row: any) => ({
              id: row.id,
              itemId: row.item_id,
              userId: row.user_id,
              name: row.name,
              category: row.category,
              quantity: row.quantity,
              effect: row.effect,
              iconType: row.icon_type,
              purchasedAt: row.purchased_at || row.created_at,
            }));

          if (itemsFromDb.length > 0) {
            let userMap = this.inMemoryInventory.get(userId);
            if (!userMap) {
              userMap = new Map();
              this.inMemoryInventory.set(userId, userMap);
            }
            userMap.clear();
            for (const it of itemsFromDb) {
              userMap.set(it.itemId, it);
            }
            return itemsFromDb;
          }
        }
      } catch (err: any) {
        this.logger.debug(`Không thể lấy inventory từ Supabase: ${err.message}`);
      }
    }

    // 2. Kiểm tra bộ nhớ tạm
    let userMap = this.inMemoryInventory.get(userId);
    if (userMap && userMap.size > 0) {
      const inMemList = Array.from(userMap.values()).filter((i) => i.quantity > 0);
      if (inMemList.length > 0) {
        return inMemList;
      }
    }

    // 3. TỰ ĐỘNG KHÔI PHỤC VĨNH VIỄN TỪ LỊCH SỬ GIAO DỊCH (spirit_stone_transactions):
    // Đảm bảo không bao giờ bị mất đồ kể cả khi server restart hoặc bảng Supabase chưa kịp tạo
    if (client) {
      try {
        const { data: txs, error: txError } = await client
          .from('spirit_stone_transactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', { ascending: true });

        if (!txError && txs && txs.length > 0) {
          const itemCounts = new Map<string, { qty: number; lastDate: string }>();

          for (const tx of txs) {
            const desc = tx.description || '';

            // Match mua: "Phù Lục Các: Mua 8x Tẩy Tủy Đan" hoặc "Phù Lục Các: Mua 1x Hộ Mệnh Phù"
            const buyMatch = desc.match(/Phù Lục Các:\s*Mua\s*(\d+)x\s*(.+)/i);
            if (buyMatch) {
              const count = parseInt(buyMatch[1], 10) || 1;
              const itemName = buyMatch[2].trim();
              const foundShopItem = DEFAULT_SHOP_ITEMS.find((it) => it.name === itemName);
              if (foundShopItem) {
                const cur = itemCounts.get(foundShopItem.id) || { qty: 0, lastDate: tx.created_at };
                cur.qty += count;
                cur.lastDate = tx.created_at;
                itemCounts.set(foundShopItem.id, cur);
              }
            }

            // Match dùng: "Sử dụng 1x Tẩy Tủy Đan"
            const useMatch = desc.match(/Sử dụng\s*(\d+)x\s*(.+)/i);
            if (useMatch) {
              const count = parseInt(useMatch[1], 10) || 1;
              const itemName = useMatch[2].trim();
              const foundShopItem = DEFAULT_SHOP_ITEMS.find((it) => it.name === itemName);
              if (foundShopItem) {
                const cur = itemCounts.get(foundShopItem.id);
                if (cur) {
                  cur.qty = Math.max(0, cur.qty - count);
                }
              }
            }
          }

          if (itemCounts.size > 0) {
            const reconstructed: UserInventoryItem[] = [];
            userMap = new Map();
            this.inMemoryInventory.set(userId, userMap);

            for (const [itemId, info] of itemCounts.entries()) {
              if (info.qty > 0) {
                const defItem = this.getItemById(itemId);
                if (defItem) {
                  const invItem: UserInventoryItem = {
                    id: `inv-${Date.now()}-${itemId}`,
                    itemId: defItem.id,
                    userId,
                    name: defItem.name,
                    category: defItem.category,
                    quantity: info.qty,
                    effect: defItem.effect,
                    iconType: defItem.iconType,
                    purchasedAt: info.lastDate || new Date().toISOString(),
                  };
                  userMap.set(itemId, invItem);
                  reconstructed.push(invItem);

                  // Đồng bộ lại vào Supabase nếu có thể
                  try {
                    await client
                      .from('user_inventory')
                      .upsert(
                        {
                          id: invItem.id,
                          user_id: userId,
                          item_id: invItem.itemId,
                          name: invItem.name,
                          category: invItem.category,
                          quantity: invItem.quantity,
                          effect: invItem.effect,
                          icon_type: invItem.iconType,
                          purchased_at: invItem.purchasedAt,
                          updated_at: new Date().toISOString(),
                        },
                        { onConflict: 'user_id,item_id' },
                      );
                  } catch (_) {}
                }
              }
            }

            if (reconstructed.length > 0) {
              this.logger.log(
                `[Shop] Đã tự động khôi phục ${reconstructed.length} loại vật phẩm từ lịch sử giao dịch cho user ${userId}!`,
              );
              return reconstructed;
            }
          }
        }
      } catch (recoveryErr: any) {
        this.logger.debug(`Lỗi khôi phục inventory từ giao dịch: ${recoveryErr.message}`);
      }
    }

    return [];
  }

  async purchaseItem(
    userId: string,
    itemId: string,
    quantity: number = 1,
  ): Promise<{
    success: boolean;
    item: ShopItem;
    quantity: number;
    totalCost: number;
    remainingSpiritStones: number;
    inventory: UserInventoryItem[];
    message: string;
  }> {
    const qty = Math.max(1, Math.floor(quantity));
    const item = this.getItemById(itemId);

    if (!item) {
      throw new NotFoundException(`Vật phẩm không tồn tại trong Phù Lục Các (ID: ${itemId})`);
    }

    if (!item.isAvailable) {
      throw new BadRequestException(`Vật phẩm "${item.name}" hiện đã hết hàng hoặc chưa mở bán!`);
    }

    const totalCost = item.price * qty;
    const profile = await this.cultivationService.getProfile(userId);

    if (profile.spiritStones < totalCost) {
      throw new BadRequestException(
        `Đạo hữu không đủ Nguyên Thạch! Cần ${totalCost} Nguyên Thạch nhưng hiện chỉ có ${profile.spiritStones}. Hãy hoàn thành thêm nhiệm vụ để tích lũy!`,
      );
    }

    // 1. Trừ Nguyên Thạch qua CultivationService & ghi nhận giao dịch SPEND
    const updatedProfile = await this.cultivationService.addSpiritStones(
      userId,
      -totalCost,
      `Phù Lục Các: Mua ${qty}x ${item.name}`,
    );

    // 2. Đảm bảo load inventory hiện tại trước khi cộng dồn
    await this.getInventory(userId);

    let userMap = this.inMemoryInventory.get(userId);
    if (!userMap) {
      userMap = new Map<string, UserInventoryItem>();
      this.inMemoryInventory.set(userId, userMap);
    }

    const existing = userMap.get(itemId);
    const newQuantity = (existing?.quantity || 0) + qty;
    const invItem: UserInventoryItem = {
      id: existing?.id || `inv-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      itemId: item.id,
      userId,
      name: item.name,
      category: item.category,
      quantity: newQuantity,
      effect: item.effect,
      iconType: item.iconType,
      purchasedAt: new Date().toISOString(),
    };
    userMap.set(itemId, invItem);

    // 3. Lưu vào Supabase user_inventory
    const client = this.supabaseService.getClient();
    if (client) {
      try {
        await client.from('user_inventory').upsert(
          {
            id: invItem.id,
            user_id: userId,
            item_id: item.id,
            name: item.name,
            category: item.category,
            quantity: newQuantity,
            effect: item.effect,
            icon_type: item.iconType,
            purchased_at: invItem.purchasedAt,
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'user_id,item_id' },
        );
      } catch (err: any) {
        this.logger.debug(`Không thể lưu user_inventory vào Supabase: ${err.message}`);
      }
    }

    const inventory = Array.from(userMap.values()).filter((i) => i.quantity > 0);

    return {
      success: true,
      item,
      quantity: qty,
      totalCost,
      remainingSpiritStones: updatedProfile.spiritStones,
      inventory,
      message: `Chúc mừng đạo hữu đã đổi thành công ${qty}x ${item.name}! Đã trừ ${totalCost} Nguyên Thạch.`,
    };
  }

  async useItem(
    userId: string,
    itemId: string,
    quantity: number = 1,
  ): Promise<{
    success: boolean;
    item: ShopItem;
    usedQuantity: number;
    remainingQuantity: number;
    effectMessage: string;
    profile: any;
    inventory: UserInventoryItem[];
  }> {
    const qty = Math.max(1, Math.floor(quantity));
    const item = this.getItemById(itemId);

    if (!item) {
      throw new NotFoundException(`Vật phẩm không tồn tại (ID: ${itemId})`);
    }

    // Tải inventory hiện tại
    const currentInventory = await this.getInventory(userId);
    const invItem = currentInventory.find((i) => i.itemId === itemId);

    if (!invItem || invItem.quantity < qty) {
      throw new BadRequestException(
        `Đạo hữu không có đủ số lượng "${item.name}" trong Túi Càn Khôn! (Hiện có: ${invItem?.quantity || 0})`,
      );
    }

    const newQuantity = invItem.quantity - qty;
    let userMap = this.inMemoryInventory.get(userId);
    if (!userMap) {
      userMap = new Map();
      this.inMemoryInventory.set(userId, userMap);
    }

    if (newQuantity <= 0) {
      userMap.delete(itemId);
    } else {
      userMap.set(itemId, { ...invItem, quantity: newQuantity });
    }

    // Cập nhật Supabase & ghi nhật ký sử dụng
    const client = this.supabaseService.getClient();
    if (client) {
      try {
        if (newQuantity <= 0) {
          await client
            .from('user_inventory')
            .delete()
            .eq('user_id', userId)
            .eq('item_id', itemId);
        } else {
          await client
            .from('user_inventory')
            .update({ quantity: newQuantity, updated_at: new Date().toISOString() })
            .eq('user_id', userId)
            .eq('item_id', itemId);
        }

        // Ghi nhận giao dịch ITEM_USE
        await client.from('spirit_stone_transactions').insert({
          user_id: userId,
          amount: 0,
          type: 'ITEM_USE',
          description: `Sử dụng ${qty}x ${item.name}`,
        });
      } catch (err: any) {
        this.logger.debug(`Lỗi cập nhật Supabase khi useItem: ${err.message}`);
      }
    }

    // Kích hoạt hiệu ứng của vật phẩm
    let effectMessage = `Đạo hữu đã sử dụng thành công ${qty}x ${item.name}!`;
    let expGained = 0;

    if (itemId === 'dan_tu_khi') {
      expGained = 250 * qty;
    } else if (itemId === 'dan_truc_co') {
      expGained = 650 * qty;
    } else if (itemId === 'dan_tay_tuy') {
      expGained = 1500 * qty;
    }

    let updatedProfile: any;
    if (expGained > 0) {
      const addExpResult = await this.cultivationService.addExp(userId, expGained);
      updatedProfile = addExpResult.profile;
      if (addExpResult.realmUp) {
        effectMessage = `🔥 ĐỘT PHÁ CẢNH GIỚI! Nuốt ${qty}x ${item.name}, đạo hữu thu nạp +${expGained} Linh Lực và đã đột phá lên ${addExpResult.profile.realmName}!`;
      } else if (addExpResult.levelUp) {
        effectMessage = `⚡ ĐỘT PHÁ TẦNG! Nuốt ${qty}x ${item.name}, đạo hữu thu nạp +${expGained} Linh Lực và thăng lên Bậc ${addExpResult.profile.subRealm}!`;
      } else {
        effectMessage = `✨ Nuốt ${qty}x ${item.name}, đan điền bừng sáng, thu nạp thành công +${expGained} Linh Lực (EXP)!`;
      }
    } else {
      updatedProfile = await this.cultivationService.getProfile(userId);
      if (itemId === 'phu_ho_menh') {
        effectMessage = `🛡️ Hộ Mệnh Phù đã được gia trì thành công! Chuỗi ngày tu luyện (Streak) của đạo hữu đã được phong ấn bảo lưu.`;
      } else if (itemId === 'phu_tu_khi') {
        effectMessage = `✨ Tụ Khí Phù đã được kích hoạt! Linh khí hội tụ, gia tăng +50% Linh Lực cho các nhiệm vụ hôm nay.`;
      } else if (itemId === 'phu_than_hanh') {
        effectMessage = `⚡ Thần Hành Phù bộc phát thần tốc, hoàn thành nhiệm vụ tức thì!`;
      } else if (itemId === 'phu_tay_tam') {
        effectMessage = `💧 Tẩy Tâm Phù hóa giải tạp niệm, xóa bỏ kiếp nạn từ Thiên Đạo!`;
      } else {
        effectMessage = `✨ Kích hoạt thành công ${item.name}: ${item.effect}`;
      }
    }

    const inventory = Array.from(userMap.values()).filter((i) => i.quantity > 0);

    return {
      success: true,
      item,
      usedQuantity: qty,
      remainingQuantity: newQuantity,
      effectMessage,
      profile: updatedProfile,
      inventory,
    };
  }
}
