import { 
  Controller, Get, Post, Body, Param, Put, UseGuards, 
  UseInterceptors, UploadedFile, BadRequestException, Res
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { Response } from 'express';
import { existsSync } from 'fs';
import { TenantsService } from './tenants.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DataSource } from 'typeorm';
import { InjectDataSource } from '@nestjs/typeorm';

@Controller('tenants')
export class TenantsController {
  constructor(
    private readonly tenantsService: TenantsService,
    @InjectDataSource() private readonly dataSource: DataSource,
  ) {}

  // Public: get tenant logo file
  @Get('logo/:filename')
  getLogo(@Param('filename') filename: string, @Res() res: Response) {
    const filePath = join(process.cwd(), 'uploads', 'logos', filename);
    if (!existsSync(filePath)) {
      return res.status(404).json({ message: 'Logo not found' });
    }
    return res.sendFile(filePath);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Body() body: { name: string; tenant_code: string; logo_url?: string; primary_color?: string }) {
    return this.tenantsService.create(body.name, body.tenant_code, body.logo_url, body.primary_color);
  }

  @UseGuards(JwtAuthGuard)
  @Get()
  findAll() {
    return this.tenantsService.findAll();
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tenantsService.findOne(id);
  }

  @UseGuards(JwtAuthGuard)
  @Put(':id')
  update(@Param('id') id: string, @Body() updateData: any) {
    return this.tenantsService.update(id, updateData);
  }

  // Upload logo image for a tenant
  @UseGuards(JwtAuthGuard)
  @Post(':id/logo')
  @UseInterceptors(FileInterceptor('logo', {
    storage: diskStorage({
      destination: './uploads/logos',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, `tenant-${req.params.id}-${uniqueSuffix}${extname(file.originalname)}`);
      },
    }),
    fileFilter: (req, file, cb) => {
      const allowed = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
      if (!allowed.includes(extname(file.originalname).toLowerCase())) {
        return cb(new BadRequestException('Only image files are allowed'), false);
      }
      cb(null, true);
    },
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  }))
  async uploadLogo(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    // Save the URL path in the DB (served via GET /api/tenants/logo/:filename)
    const logoUrl = `/api/tenants/logo/${file.filename}`;
    await this.tenantsService.update(id, { logo_url: logoUrl });
    return { logo_url: logoUrl, filename: file.filename };
  }

  // Migrate old data (tenant_id = NULL) to belong to a specific tenant
  @UseGuards(JwtAuthGuard)
  @Post(':id/migrate-data')
  async migrateData(@Param('id') tenantId: string) {
    const tables = [
      'customers', 'products', 'invoices', 'expenses',
      'purchases', 'debts', 'gold_prices', 'cash_box',
      'transfers', 'inventory_checks', 'notifications', 'users',
    ];
    const results: Record<string, number> = {};
    for (const table of tables) {
      try {
        const result = await this.dataSource.query(
          `UPDATE "${table}" SET tenant_id = $1 WHERE tenant_id IS NULL`,
          [tenantId],
        );
        results[table] = result[1] ?? 0;
      } catch (e) {
        results[table] = -1;
      }
    }
    return { message: 'تم تحديث البيانات القديمة بنجاح', results };
  }
}
