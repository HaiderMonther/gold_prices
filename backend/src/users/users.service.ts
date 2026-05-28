import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private repo: Repository<User>,
  ) {}

  async findAll(tenantId?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({ where, select: ['id', 'name', 'username', 'role', 'is_active', 'created_at'] });
  }

  async findOne(id: string) {
    const user = await this.repo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('المستخدم غير موجود');
    return user;
  }

  async create(dto: { name: string; username: string; password: string; role: UserRole }, tenantId?: string) {
    const where: any = { username: dto.username };
    if (tenantId) where.tenant_id = tenantId;
    const exists = await this.repo.findOne({ where: { username: dto.username } });
    if (exists) throw new ConflictException('اسم المستخدم موجود مسبقاً');
    const hash = await bcrypt.hash(dto.password, 10);
    const user = this.repo.create({ ...dto, password_hash: hash, tenant_id: tenantId || null });
    const saved = await this.repo.save(user);
    const { password_hash, ...rest } = saved;
    return rest;
  }

  async update(id: string, dto: Partial<{ name: string; role: UserRole; is_active: boolean; password: string }>) {
    const user = await this.findOne(id);
    if (dto.password) {
      user.password_hash = await bcrypt.hash(dto.password, 10);
    }
    Object.assign(user, dto);
    const saved = await this.repo.save(user);
    const { password_hash, ...rest } = saved;
    return rest;
  }

  async remove(id: string) {
    const user = await this.findOne(id);
    user.is_active = false;
    await this.repo.save(user);
    return { message: 'تم تعطيل المستخدم' };
  }

  async seedAdmin() {
    const exists = await this.repo.findOne({ where: { username: 'admin' } });
    if (!exists) {
      const hash = await bcrypt.hash('admin123', 10);
      await this.repo.save(
        this.repo.create({ name: 'مدير النظام', username: 'admin', password_hash: hash, role: UserRole.ADMIN }),
      );
      console.log('✅ Admin user created: admin / admin123');
    }
  }
}
