import { Controller, Post, Body, Get, Param, NotFoundException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { IsString } from 'class-validator';
import { TenantsService } from '../tenants/tenants.service';

class LoginDto {
  @IsString()
  username: string;

  @IsString()
  password: string;

  @IsString()
  tenant_code: string;
}

class RegisterDto {
  @IsString()
  tenant_name: string;

  @IsString()
  tenant_code: string;

  @IsString()
  admin_username: string;

  @IsString()
  admin_password: string;
}

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private tenantsService: TenantsService
  ) {}

  @Post('login')
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto.username, dto.password, dto.tenant_code);
  }

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(
      dto.tenant_name, 
      dto.tenant_code, 
      dto.admin_username, 
      dto.admin_password
    );
  }

  // Public endpoint: get tenant branding info by tenant_code (no auth required)
  @Get('tenant/:code')
  async getTenantInfo(@Param('code') code: string) {
    try {
      const tenant = await this.tenantsService.findByCode(code);
      if (!tenant.is_active) {
        throw new NotFoundException('حساب هذه الشركة متوقف');
      }
      return { 
        id: tenant.id, 
        name: tenant.name, 
        tenant_code: tenant.tenant_code,
        logo_url: tenant.logo_url,
        primary_color: tenant.primary_color,
      };
    } catch (e) {
      throw new NotFoundException('لم يتم العثور على الشركة، تحقق من الكود');
    }
  }
}
