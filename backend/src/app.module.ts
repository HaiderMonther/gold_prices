import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { MulterModule } from '@nestjs/platform-express';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CustomersModule } from './customers/customers.module';
import { ProductsModule } from './products/products.module';
import { InvoicesModule } from './invoices/invoices.module';
import { PurchasesModule } from './purchases/purchases.module';
import { ExpensesModule } from './expenses/expenses.module';
import { DebtsModule } from './debts/debts.module';
import { GoldPricesModule } from './gold-prices/gold-prices.module';
import { InventoryModule } from './inventory/inventory.module';
import { ReportsModule } from './reports/reports.module';
import { CashBoxModule } from './cash-box/cash-box.module';
import { TransfersModule } from './transfers/transfers.module';
import { TenantsModule } from './tenants/tenants.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { CronModule } from './cron/cron.module';
import { PaymentsModule } from './payments/payments.module';
import { NotificationsModule } from './notifications/notifications.module';
// Entities
import { User } from './users/user.entity';
import { Customer } from './customers/customer.entity';
import { Product } from './products/product.entity';
import { Invoice } from './invoices/invoice.entity';
import { InvoiceItem } from './invoices/invoice-item.entity';
import { Purchase } from './purchases/purchase.entity';
import { Expense } from './expenses/expense.entity';
import { Debt } from './debts/debt.entity';
import { GoldPrice } from './gold-prices/gold-price.entity';
import { InventoryCheck } from './inventory/inventory-check.entity';
import { CashBox } from './cash-box/cash-box.entity';
import { Transfer } from './transfers/transfer.entity';
import { Tenant } from './tenants/tenant.entity';
import { Subscription } from './subscriptions/subscription.entity';
import { Notification } from './notifications/notification.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ScheduleModule.forRoot(),
    MulterModule.register({ dest: './uploads' }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get('DB_HOST', 'localhost'),
        port: parseInt(config.get('DB_PORT', '5432')),
        username: config.get('DB_USERNAME', 'postgres'),
        password: config.get('DB_PASSWORD', 'postgres'),
        database: config.get('DB_DATABASE', 'gold_system'),
        entities: [
          User, Customer, Product, Invoice, InvoiceItem,
          Purchase, Expense, Debt, GoldPrice, InventoryCheck,
          CashBox, Transfer, Tenant, Subscription, Notification,
        ],
        synchronize: true,
        logging: false,
      }),
    }),
    AuthModule,
    UsersModule,
    CustomersModule,
    ProductsModule,
    InvoicesModule,
    PurchasesModule,
    ExpensesModule,
    DebtsModule,
    GoldPricesModule,
    InventoryModule,
    ReportsModule,
    CashBoxModule,
    TransfersModule,
    TenantsModule,
    SubscriptionsModule,
    CronModule,
    PaymentsModule,
    NotificationsModule,
  ],
})
export class AppModule {}
