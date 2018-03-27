import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ExchangePricesComponent } from './exchange-prices.component';

describe('ExchangePricesComponent', () => {
  let component: ExchangePricesComponent;
  let fixture: ComponentFixture<ExchangePricesComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ExchangePricesComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ExchangePricesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
