import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Transfer } from './transfer.entity';

@Injectable()
export class TransfersService {
  constructor(
    @InjectRepository(Transfer) private repo: Repository<Transfer>,
  ) {}

  findAll(tenantId?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({
      where,
      relations: ['from_customer', 'to_customer', 'user'],
      order: { created_at: 'DESC' },
    });
  }

  create(data: Partial<Transfer>) {
    const transfer = this.repo.create(data);
    return this.repo.save(transfer);
  }

  async remove(id: string) {
    await this.repo.delete(id);
    return { deleted: true };
  }
}
