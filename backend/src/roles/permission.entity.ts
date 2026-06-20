import { Entity, PrimaryGeneratedColumn, Column, ManyToMany } from 'typeorm';
import { Role } from './role.entity';

@Entity('permissions')
export class Permission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  name: string; // e.g. "view_invoices"

  @Column()
  display_name: string; // e.g. "عرض الفواتير"

  @Column()
  group: string; // e.g. "الفواتير"

  @Column({ default: 0 })
  sort_order: number;

  @ManyToMany(() => Role, (role) => role.permissions)
  roles: Role[];
}
