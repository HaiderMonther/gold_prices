import {
  Entity, PrimaryGeneratedColumn, Column, ManyToMany, JoinTable, CreateDateColumn,
} from 'typeorm';
import { Permission } from './permission.entity';

@Entity('roles')
export class Role {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  name: string; // e.g. "admin"

  @Column()
  display_name: string; // e.g. "مدير النظام"

  @Column({ nullable: true })
  description: string;

  @Column({ default: false })
  is_system: boolean; // system roles cannot be deleted

  @CreateDateColumn()
  created_at: Date;

  @ManyToMany(() => Permission, (permission) => permission.roles, { eager: true })
  @JoinTable({
    name: 'role_permissions',
    joinColumn: { name: 'role_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'permission_id', referencedColumnName: 'id' },
  })
  permissions: Permission[];
}
