import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenant } from './tenant.entity';

@Injectable()
export class TenantsService {
  constructor(
    @InjectRepository(Tenant)
    private tenantsRepository: Repository<Tenant>,
  ) {}

  async create(name: string, tenant_code: string, logo_url?: string, primary_color?: string): Promise<Tenant> {
    const tenant = this.tenantsRepository.create({ 
      name, 
      tenant_code: tenant_code.toLowerCase().replace(/[^a-z0-9]/g, ''),
      logo_url,
      primary_color,
    });
    return await this.tenantsRepository.save(tenant);
  }

  async findAll(): Promise<Tenant[]> {
    return await this.tenantsRepository.find({ order: { created_at: 'DESC' } });
  }

  async findOne(id: string): Promise<Tenant> {
    const tenant = await this.tenantsRepository.findOne({ where: { id } });
    if (!tenant) {
      throw new NotFoundException(`Tenant with ID ${id} not found`);
    }
    return tenant;
  }

  async findByCode(tenant_code: string): Promise<Tenant> {
    const tenant = await this.tenantsRepository.findOne({ where: { tenant_code: tenant_code.toLowerCase() } });
    if (!tenant) {
      throw new NotFoundException(`لم يتم العثور على شركة بهذا الكود`);
    }
    return tenant;
  }

  // Kept for backward compatibility
  async findBySubdomain(subdomain: string): Promise<Tenant> {
    const tenant = await this.tenantsRepository.findOne({ where: { subdomain } });
    if (!tenant) {
      throw new NotFoundException(`Tenant with subdomain ${subdomain} not found`);
    }
    return tenant;
  }

  async update(id: string, updateData: Partial<Tenant>): Promise<Tenant> {
    // If tenant_code is being updated, sanitize it
    if (updateData.tenant_code) {
      updateData.tenant_code = updateData.tenant_code.toLowerCase().replace(/[^a-z0-9]/g, '');
    }
    await this.tenantsRepository.update(id, updateData);
    return this.findOne(id);
  }
}
