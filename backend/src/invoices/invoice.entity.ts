import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn, OneToMany, OneToOne,
} from 'typeorm';
import { Customer } from '../customers/customer.entity';
import { User } from '../users/user.entity';
import { InvoiceItem } from './invoice-item.entity';
import { Debt } from '../debts/debt.entity';
import { Tenant } from '../tenants/tenant.entity';
export enum InvoiceType {
  SALE = 'sale',
  RETURN = 'return',
  PURCHASE = 'purchase',
}

export enum InvoiceStatus {
  COMPLETED = 'completed',
  DRAFT = 'draft',
  CANCELLED = 'cancelled',
}

@Entity('invoices')
export class Invoice {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  invoice_number: string;

  @Column({ type: 'varchar', default: InvoiceType.SALE })
  type: InvoiceType;

  @Column({ nullable: true })
  customer_id: string;

  @ManyToOne(() => Customer, (c) => c.invoices, { nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer: Customer;

  @Column({ nullable: true })
  user_id: string;

  @ManyToOne(() => User, (u) => u.invoices, { nullable: true })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  total_amount: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  paid_amount: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  remaining: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  discount: number;

  @Column({ type: 'varchar', default: InvoiceStatus.COMPLETED })
  status: InvoiceStatus;

  @Column({ nullable: true })
  notes: string;

  @CreateDateColumn()
  created_at: Date;

  @OneToMany(() => InvoiceItem, (item) => item.invoice, { cascade: true })
  items: InvoiceItem[];

  @OneToOne(() => Debt, (d) => d.invoice)
  debt: Debt;

  @ManyToOne(() => Tenant, { nullable: true })
  @JoinColumn({ name: 'tenant_id' })
  tenant: Tenant;

  @Column({ nullable: true })
  tenant_id: string;
}
