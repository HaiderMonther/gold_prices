import { Controller, Post, Body, Get, Query, Res, HttpStatus } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { Response } from 'express';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('checkout')
  async createCheckout(@Body() body: { tenantId: string; plan: string }) {
    return this.paymentsService.createSubscriptionCheckout(body.tenantId, body.plan);
  }

  @Get('callback')
  async verifyPayment(@Query('token') token: string, @Res() res: Response) {
    if (!token) {
      return res.redirect('http://localhost:5173/payment/failed');
    }

    const result = await this.paymentsService.verifyPaymentCallback(token);
    
    if (result.success) {
      return res.redirect(`http://localhost:5173/payment/success?tenant=${result.tenantId}`);
    } else {
      return res.redirect('http://localhost:5173/payment/failed');
    }
  }
}
