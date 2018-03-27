import { TestBed, inject } from '@angular/core/testing';

import { ExchangeDataServiceService } from './exchange-data-service.service';

describe('ExchangeDataServiceService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [ExchangeDataServiceService]
    });
  });

  it('should be created', inject([ExchangeDataServiceService], (service: ExchangeDataServiceService) => {
    expect(service).toBeTruthy();
  }));
});
