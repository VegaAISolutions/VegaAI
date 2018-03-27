import { TestBed, inject } from '@angular/core/testing';

import { OrderDataService } from './order-data.service';

describe('OrderDataService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [OrderDataService]
    });
  });

  it('should be created', inject([OrderDataService], (service: OrderDataService) => {
    expect(service).toBeTruthy();
  }));
});
