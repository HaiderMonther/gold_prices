import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn, OneToMany,
} from 'typeorm';
import { User } from '../users/user.entity';
import { InvoiceItem } from '../invoices/invoice-item.entity';
import { Tenant } from '../tenants/tenant.entity';
export enum ProductStatus {
  AVAILABLE = 'available',
  SOLD = 'sold',
  RESERVED = 'reserved',
}

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ type: 'decimal', precision: 10, scale: 3 })
  weight: number;

  @Column()
  karat: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  craft_price: number;

  @Column({ nullable: true, unique: true })
  barcode: string;

  @Column({ type: 'enum', enum: ProductStatus, default: ProductStatus.AVAILABLE })
  status: ProductStatus;

  @Column({ nullable: true })
  created_by: string;

  @ManyToOne(() => User, (u) => u.products, { nullable: true })
  @JoinColumn({ name: 'created_by' })
  created_by_user: User;

  @CreateDateColumn()
  created_at: Date;

  @OneToMany(() => InvoiceItem, (item) => item.product)
  invoice_items: InvoiceItem[];

  @ManyToOne(() => Tenant, { nullable: true })
  @JoinColumn({ name: 'tenant_id' })
  tenant: Tenant;

  @Column({ nullable: true })
  tenant_id: string;
}
