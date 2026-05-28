import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CashBox } from './cash-box.entity';
import { CashBoxService } from './cash-box.service';
import { CashBoxController } from './cash-box.controller';

@Module({
  imports: [TypeOrmModule.forFeature([CashBox])],
  providers: [CashBoxService],
  controllers: [CashBoxController],
  exports: [CashBoxService],
})
export class CashBoxModule {}
