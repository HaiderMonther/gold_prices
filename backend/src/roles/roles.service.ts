import { Injectable, OnApplicationBootstrap, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Role } from './role.entity';
import { Permission } from './permission.entity';

// All system permissions grouped by category
const DEFAULT_PERMISSIONS: { name: string; display_name: string; group: string; sort_order: number }[] = [
  // الفواتير
  { name: 'view_invoices', display_name: 'عرض الفواتير', group: 'الفواتير', sort_order: 1 },
  { name: 'create_invoices', display_name: 'إنشاء الفواتير', group: 'الفواتير', sort_order: 2 },
  { name: 'delete_invoices', display_name: 'حذف الفواتير', group: 'الفواتير', sort_order: 3 },
  // المنتجات
  { name: 'view_products', display_name: 'عرض المنتجات', group: 'المنتجات', sort_order: 10 },
  { name: 'create_products', display_name: 'إضافة منتجات', group: 'المنتجات', sort_order: 11 },
  { name: 'edit_products', display_name: 'تعديل المنتجات', group: 'المنتجات', sort_order: 12 },
  { name: 'delete_products', display_name: 'حذف المنتجات', group: 'المنتجات', sort_order: 13 },
  // العملاء
  { name: 'view_customers', display_name: 'عرض العملاء', group: 'العملاء', sort_order: 20 },
  { name: 'create_customers', display_name: 'إضافة عملاء', group: 'العملاء', sort_order: 21 },
  { name: 'edit_customers', display_name: 'تعديل العملاء', group: 'العملاء', sort_order: 22 },
  // المشتريات
  { name: 'view_purchases', display_name: 'عرض المشتريات', group: 'المشتريات', sort_order: 30 },
  { name: 'create_purchases', display_name: 'إنشاء مشتريات', group: 'المشتريات', sort_order: 31 },
  // المصروفات
  { name: 'view_expenses', display_name: 'عرض المصروفات', group: 'المصروفات', sort_order: 40 },
  { name: 'create_expenses', display_name: 'إضافة مصروفات', group: 'المصروفات', sort_order: 41 },
  // التقارير
  { name: 'view_reports', display_name: 'عرض التقارير', group: 'التقارير', sort_order: 50 },
  { name: 'export_reports', display_name: 'تصدير التقارير', group: 'التقارير', sort_order: 51 },
  // الصندوق
  { name: 'view_cashbox', display_name: 'عرض الصندوق', group: 'الصندوق', sort_order: 60 },
  { name: 'manage_cashbox', display_name: 'إدارة الصندوق', group: 'الصندوق', sort_order: 61 },
  // الحوالات
  { name: 'view_transfers', display_name: 'عرض الحوالات', group: 'الحوالات', sort_order: 70 },
  { name: 'create_transfers', display_name: 'إنشاء حوالات', group: 'الحوالات', sort_order: 71 },
  // الديون
  { name: 'view_debts', display_name: 'عرض الديون', group: 'الديون', sort_order: 80 },
  { name: 'manage_debts', display_name: 'إدارة الديون', group: 'الديون', sort_order: 81 },
  // الجرد
  { name: 'view_inventory', display_name: 'عرض الجرد', group: 'الجرد', sort_order: 90 },
  { name: 'manage_inventory', display_name: 'إدارة الجرد', group: 'الجرد', sort_order: 91 },
  // أسعار الذهب
  { name: 'view_gold_prices', display_name: 'عرض أسعار الذهب', group: 'أسعار الذهب', sort_order: 100 },
  { name: 'manage_gold_prices', display_name: 'تعديل أسعار الذهب', group: 'أسعار الذهب', sort_order: 101 },
  // المستخدمون
  { name: 'view_users', display_name: 'عرض المستخدمين', group: 'المستخدمون', sort_order: 110 },
  { name: 'manage_users', display_name: 'إدارة المستخدمين', group: 'المستخدمون', sort_order: 111 },
  // الإعدادات
  { name: 'view_settings', display_name: 'عرض الإعدادات', group: 'الإعدادات', sort_order: 120 },
  { name: 'manage_settings', display_name: 'تعديل الإعدادات', group: 'الإعدادات', sort_order: 121 },
];

@Injectable()
export class RolesService implements OnApplicationBootstrap {
  constructor(
    @InjectRepository(Role) private roleRepo: Repository<Role>,
    @InjectRepository(Permission) private permRepo: Repository<Permission>,
  ) {}

  async onApplicationBootstrap() {
    await this.seedPermissions();
    await this.seedDefaultRoles();
  }

  private async seedPermissions() {
    for (const p of DEFAULT_PERMISSIONS) {
      const exists = await this.permRepo.findOne({ where: { name: p.name } });
      if (!exists) {
        await this.permRepo.save(this.permRepo.create(p));
      }
    }
  }

  private async seedDefaultRoles() {
    const allPerms = await this.permRepo.find();
    const byName = (name: string) => allPerms.find((p) => p.name === name);

    const defaultRoles = [
      {
        name: 'admin',
        display_name: 'مدير النظام',
        description: 'صلاحيات كاملة على جميع أقسام النظام',
        is_system: true,
        permissionNames: allPerms.map((p) => p.name), // all permissions
      },
      {
        name: 'cashier',
        display_name: 'كاشير',
        description: 'صلاحيات البيع والفواتير اليومية',
        is_system: true,
        permissionNames: [
          'view_invoices', 'create_invoices',
          'view_products',
          'view_customers', 'create_customers',
          'view_gold_prices',
        ],
      },
      {
        name: 'accountant',
        display_name: 'محاسب',
        description: 'صلاحيات الحسابات والتقارير المالية',
        is_system: true,
        permissionNames: [
          'view_invoices',
          'view_purchases',
          'view_expenses', 'create_expenses',
          'view_reports', 'export_reports',
          'view_cashbox', 'manage_cashbox',
          'view_transfers', 'create_transfers',
          'view_debts', 'manage_debts',
          'view_customers',
          'view_gold_prices',
        ],
      },
    ];

    for (const rd of defaultRoles) {
      const exists = await this.roleRepo.findOne({ where: { name: rd.name } });
      if (!exists) {
        const perms = rd.permissionNames.map((n) => byName(n)).filter(Boolean) as Permission[];
        const role = this.roleRepo.create({
          name: rd.name,
          display_name: rd.display_name,
          description: rd.description,
          is_system: rd.is_system,
          permissions: perms,
        });
        await this.roleRepo.save(role);
      }
    }
  }

  findAllRoles() {
    return this.roleRepo.find({ order: { created_at: 'ASC' } });
  }

  findAllPermissions() {
    return this.permRepo.find({ order: { sort_order: 'ASC' } });
  }

  async findRoleById(id: string) {
    const role = await this.roleRepo.findOne({ where: { id } });
    if (!role) throw new NotFoundException('الدور غير موجود');
    return role;
  }

  async createRole(dto: { name: string; display_name: string; description?: string; permission_ids?: string[] }) {
    const perms = dto.permission_ids?.length
      ? await this.permRepo.findBy({ id: In(dto.permission_ids) })
      : [];
    const role = this.roleRepo.create({
      name: dto.name,
      display_name: dto.display_name,
      description: dto.description || '',
      permissions: perms,
    });
    return this.roleRepo.save(role);
  }

  async updateRole(id: string, dto: { display_name?: string; description?: string; permission_ids?: string[] }) {
    const role = await this.findRoleById(id);
    if (dto.display_name) role.display_name = dto.display_name;
    if (dto.description !== undefined) role.description = dto.description;
    if (dto.permission_ids !== undefined) {
      role.permissions = dto.permission_ids.length
        ? await this.permRepo.findBy({ id: In(dto.permission_ids) })
        : [];
    }
    return this.roleRepo.save(role);
  }

  async deleteRole(id: string) {
    const role = await this.findRoleById(id);
    if (role.is_system) throw new Error('لا يمكن حذف الأدوار الأساسية للنظام');
    return this.roleRepo.remove(role);
  }
}
