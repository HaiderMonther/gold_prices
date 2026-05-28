import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany,
} from 'typeorm';
import { Invoice } from '../invoices/invoice.entity';
import { Purchase } from '../purchases/purchase.entity';
import { Expense } from '../expenses/expense.entity';
import { GoldPrice } from '../gold-prices/gold-price.entity';
import { Product } from '../products/product.entity';
import { InventoryCheck } from '../inventory/inventory-check.entity';
import { Tenant } from '../tenants/tenant.entity';
import { JoinColumn, ManyToOne } from 'typeorm';
export enum UserRole {
  ADMIN = 'admin',
  CASHIER = 'cashier',
  ACCOUNTANT = 'accountant',
  SUPER_ADMIN = 'super_admin',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  username: string;

  @Column()
  password_hash: string;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.CASHIER })
  role: UserRole;

  @Column({ default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @OneToMany(() => Invoice, (invoice) => invoice.user)
  invoices: Invoice[];

  @OneToMany(() => Purchase, (purchase) => purchase.user)
  purchases: Purchase[];

  @OneToMany(() => Expense, (expense) => expense.user)
  expenses: Expense[];

  @OneToMany(() => GoldPrice, (gp) => gp.updated_by_user)
  gold_prices: GoldPrice[];

  @OneToMany(() => Product, (p) => p.created_by_user)
  products: Product[];

  @OneToMany(() => InventoryCheck, (ic) => ic.user)
  inventory_checks: InventoryCheck[];

  @ManyToOne(() => Tenant, { nullable: true })
  @JoinColumn({ name: 'tenant_id' })
  tenant: Tenant;

  @Column({ nullable: true })
  tenant_id: string;
}
