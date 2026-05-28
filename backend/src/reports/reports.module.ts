import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReportsService } from './reports.service';
import { ReportsController } from './reports.controller';
import { Invoice } from '../invoices/invoice.entity';
import { InvoiceItem } from '../invoices/invoice-item.entity';
import { Expense } from '../expenses/expense.entity';
import { Purchase } from '../purchases/purchase.entity';
import { Product } from '../products/product.entity';
import { Debt } from '../debts/debt.entity';
import { Customer } from '../customers/customer.entity';
import { Transfer } from '../transfers/transfer.entity';

@Module({
  imports: [TypeOrmModule.forFeature([
    Invoice, InvoiceItem, Expense, Purchase, Product, Debt, Customer, Transfer,
  ])],
  providers: [ReportsService],
  controllers: [ReportsController],
})
export class ReportsModule {}
