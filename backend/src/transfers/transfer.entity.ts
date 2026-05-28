import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn,
} from 'typeorm';
import { Customer } from '../customers/customer.entity';
import { User } from '../users/user.entity';
import { Tenant } from '../tenants/tenant.entity';
export enum TransferCurrency {
  IQD = 'IQD',
  USD = 'USD',
}

@Entity('transfers')
export class Transfer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  from_customer_id: string;

  @ManyToOne(() => Customer, { nullable: true })
  @JoinColumn({ name: 'from_customer_id' })
  from_customer: Customer;

  @Column({ nullable: true })
  to_customer_id: string;

  @ManyToOne(() => Customer, { nullable: true })
  @JoinColumn({ name: 'to_customer_id' })
  to_customer: Customer;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column({ type: 'enum', enum: TransferCurrency, default: TransferCurrency.IQD })
  currency: TransferCurrency;

  @Column({ nullable: true })
  description: string;

  @Column({ nullable: true })
  user_id: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @CreateDateColumn()
  created_at: Date;

  @ManyToOne(() => Tenant, { nullable: true })
  @JoinColumn({ name: 'tenant_id' })
  tenant: Tenant;

  @Column({ nullable: true })
  tenant_id: string;
}
