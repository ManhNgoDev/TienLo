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
    if (client) {
      try {
        const { data, error } = await client
          .from('user_inventory')
          .select('*')
          .eq('user_id', userId);

        if (!error && data && data.length > 0) {
          return data.map((row: any) => ({
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
        }
      } catch (err: any) {
        this.logger.debug(`Không thể lấy inventory từ Supabase: ${err.message}`);
      }
    }

    const userMap = this.inMemoryInventory.get(userId) || new Map<string, UserInventoryItem>();
    return Array.from(userMap.values());
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

    // 1. Trừ Nguyên Thạch qua CultivationService
    const updatedProfile = await this.cultivationService.addSpiritStones(
      userId,
      -totalCost,
      `Phù Lục Các: Mua ${qty}x ${item.name}`,
    );

    // 2. Thêm vào túi đồ (In-memory & Supabase)
    const client = this.supabaseService.getClient();
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

    const inventory = Array.from(userMap.values());

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
}
