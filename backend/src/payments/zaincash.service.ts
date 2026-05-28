import { Injectable, Logger } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import axios from 'axios';

@Injectable()
export class ZaincashService {
  private readonly logger = new Logger(ZaincashService.name);
  
  // In a real app, these come from ConfigService / .env
  private readonly ZAINCASH_URL = process.env.ZAINCASH_URL || 'https://test.zaincash.iq/transaction/init';
  private readonly ZAINCASH_PAY_URL = process.env.ZAINCASH_PAY_URL || 'https://test.zaincash.iq/transaction/pay?id=';
  private readonly MERCHANT_ID = process.env.ZAINCASH_MERCHANT_ID || '5ffacf6612b5777c6d44266f'; // Test merchant
  private readonly MERCHANT_SECRET = process.env.ZAINCASH_MERCHANT_SECRET || '$2y$10$hBbAZo2GfSSvyqAyV2OqgOzvDbghak.29vJpWc6R.D4q5Z6y76rKG'; // Test secret
  private readonly MSISDN = process.env.ZAINCASH_MSISDN || '9647835077893'; // Test number
  
  async initTransaction(amount: number, orderId: string, redirectUrl: string): Promise<string> {
    const payload = {
      amount,
      serviceType: 'subscription',
      msisdn: this.MSISDN,
      orderId,
      redirectUrl,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + (60 * 60 * 4), // 4 hours expiration
    };

    // Sign payload
    const token = jwt.sign(payload, this.MERCHANT_SECRET);
    
    try {
      const response = await axios.post(this.ZAINCASH_URL, {
        token,
        merchantId: this.MERCHANT_ID,
        lang: 'ar'
      });

      if (response.data?.id) {
        // Return the payment URL that the user needs to visit
        return `${this.ZAINCASH_PAY_URL}${response.data.id}`;
      } else {
        this.logger.error('ZainCash init failed: ' + JSON.stringify(response.data));
        throw new Error('Failed to initialize ZainCash transaction');
      }
    } catch (error) {
      this.logger.error('ZainCash request failed', error);
      throw error;
    }
  }

  decodeToken(token: string): any {
    try {
      return jwt.verify(token, this.MERCHANT_SECRET);
    } catch (e) {
      this.logger.error('Failed to decode ZainCash token', e);
      return null;
    }
  }
}
