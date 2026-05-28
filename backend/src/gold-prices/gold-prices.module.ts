import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GoldPricesService } from './gold-prices.service';
import { GoldPricesController } from './gold-prices.controller';
import { GoldPrice } from './gold-price.entity';

@Module({
  imports: [TypeOrmModule.forFeature([GoldPrice])],
  providers: [GoldPricesService],
  controllers: [GoldPricesController],
  exports: [GoldPricesService],
})
export class GoldPricesModule {}
