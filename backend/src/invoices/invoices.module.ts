import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InvoicesService } from './invoices.service';
import { InvoicesController } from './invoices.controller';
import { Invoice } from './invoice.entity';
import { InvoiceItem } from './invoice-item.entity';
import { Product } from '../products/product.entity';
import { Customer } from '../customers/customer.entity';
import { User } from '../users/user.entity';
import { Debt } from '../debts/debt.entity';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Invoice, InvoiceItem, Product, Customer, User, Debt]),
    NotificationsModule,
  ],
  providers: [InvoicesService],
  controllers: [InvoicesController],
  exports: [InvoicesService],
})
export class InvoicesModule {}
