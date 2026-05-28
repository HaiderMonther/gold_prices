import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn,
} from 'typeorm';
import { Invoice } from './invoice.entity';
import { Product } from '../products/product.entity';
import { Tenant } from '../tenants/tenant.entity';
@Entity('invoice_items')
export class InvoiceItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  invoice_id: string;

  @ManyToOne(() => Invoice, (inv) => inv.items)
  @JoinColumn({ name: 'invoice_id' })
  invoice: Invoice;

  @Column({ nullable: true })
  product_id: string;

  @ManyToOne(() => Product, (p) => p.invoice_items, { nullable: true })
  @JoinColumn({ name: 'product_id' })
  product: Product;

  @Column({ nullable: true })
  item_name: string;

  @Column({ type: 'decimal', precision: 10, scale: 3 })
  weight: number;

  @Column()
  karat: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price_per_gram: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  craft_price: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  total_price: number;

  @ManyToOne(() => Tenant, { nullable: true })
  @JoinColumn({ name: 'tenant_id' })
  tenant: Tenant;

  @Column({ nullable: true })
  tenant_id: string;
}
