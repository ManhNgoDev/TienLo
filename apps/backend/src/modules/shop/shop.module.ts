import { Module } from '@nestjs/common';
import { ShopService } from './shop.service.js';
import { ShopController } from './shop.controller.js';
import { CultivationModule } from '../cultivation/cultivation.module.js';
import { DatabaseModule } from '../database/database.module.js';

@Module({
  imports: [CultivationModule, DatabaseModule],
  controllers: [ShopController],
  providers: [ShopService],
  exports: [ShopService],
})
export class ShopModule {}
