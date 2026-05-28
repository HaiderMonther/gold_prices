import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany,
} from 'typeorm';
import { Invoice } from '../invoices/invoice.entity';
import { Debt } from '../debts/debt.entity';
import { Tenant } from '../tenants/tenant.entity';
import { JoinColumn, ManyToOne } from 'typeorm';
export enum CustomerType {
  CLIENT = 'client',
  TRADER = 'trader',
  WORKSHOP = 'workshop',
}

@Entity('customers')
export class Customer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ type: 'enum', enum: CustomerType, default: CustomerType.CLIENT })
  type: CustomerType;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true })
  address: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  debt_balance: number;

  @Column({ type: 'decimal', precision: 10, scale: 3, default: 0 })
  gold_balance: number;

  @Column({ nullable: true })
  notes: string;

  @CreateDateColumn()
  created_at: Date;

  @OneToMany(() => Invoice, (inv) => inv.customer)
  invoices: Invoice[];

  @OneToMany(() => Debt, (d) => d.customer)
  debts: Debt[];

  @ManyToOne(() => Tenant, { nullable: true })
  @JoinColumn({ name: 'tenant_id' })
  tenant: Tenant;

  @Column({ nullable: true })
  tenant_id: string;
}
