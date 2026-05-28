import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../users/user.entity';
import { TenantsService } from '../tenants/tenants.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private usersRepo: Repository<User>,
    private jwtService: JwtService,
    private tenantsService: TenantsService,
  ) {}

  async login(username: string, password: string, tenantCode?: string) {
    // Super admin login: no tenant_code required
    const user = await this.usersRepo.findOne({ where: { username }, relations: ['tenant'] });
    if (!user || !user.is_active) {
      throw new UnauthorizedException('اسم المستخدم أو كلمة المرور غير صحيحة');
    }

    if (user.role === 'super_admin') {
      // Super admin can login without a tenant code
      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) {
        throw new UnauthorizedException('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
      const payload = { sub: user.id, username: user.username, role: user.role, tenantId: null };
      return {
        access_token: this.jwtService.sign(payload),
        user: { id: user.id, name: user.name, username: user.username, role: user.role, tenantId: null },
        tenant: null,
      };
    }

    // Regular users MUST provide a tenant_code
    if (!tenantCode) {
      throw new UnauthorizedException('يرجى إدخال كود الشركة');
    }

    // Find and validate the tenant
    let tenant;
    try {
      tenant = await this.tenantsService.findByCode(tenantCode);
    } catch (e) {
      throw new UnauthorizedException('كود الشركة غير صحيح أو غير موجود');
    }

    if (!tenant.is_active) {
      throw new UnauthorizedException('حساب هذه الشركة موقوف، يرجى التواصل مع الدعم الفني');
    }

    // Validate that the user belongs to this tenant
    if (user.tenant_id && user.tenant_id !== tenant.id) {
      throw new UnauthorizedException('هذا المستخدم لا ينتمي لهذه الشركة');
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      throw new UnauthorizedException('اسم المستخدم أو كلمة المرور غير صحيحة');
    }

    const payload = { sub: user.id, username: user.username, role: user.role, tenantId: tenant.id };
    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        role: user.role,
        tenantId: tenant.id,
      },
      tenant: {
        id: tenant.id,
        name: tenant.name,
        tenant_code: tenant.tenant_code,
        logo_url: tenant.logo_url,
        primary_color: tenant.primary_color,
      },
    };
  }

  async validateUser(userId: string) {
    return this.usersRepo.findOne({ where: { id: userId } });
  }

  async register(tenantName: string, tenantCode: string, adminUsername: string, adminPassword: string) {
    try {
      const existing = await this.tenantsService.findByCode(tenantCode);
      if (existing) throw new UnauthorizedException('كود الشركة مستخدم مسبقاً');
    } catch(e) {
      if (e instanceof UnauthorizedException) throw e;
      // If it throws NotFoundException, it means the code is available
    }

    const tenant = await this.tenantsService.create(tenantName, tenantCode);
    await this.tenantsService.update(tenant.id, { is_active: false });

    const password_hash = await bcrypt.hash(adminPassword, 10);
    const user = this.usersRepo.create({
      name: 'المدير العام',
      username: adminUsername,
      password_hash,
      role: UserRole.ADMIN,
      tenant_id: tenant.id,
      is_active: true
    });
    await this.usersRepo.save(user);

    return { tenantId: tenant.id };
  }
}
