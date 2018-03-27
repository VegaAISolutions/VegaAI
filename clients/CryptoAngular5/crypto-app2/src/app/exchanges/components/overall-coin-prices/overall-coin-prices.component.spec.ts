import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { OverallCoinPricesComponent } from './overall-coin-prices.component';

describe('OverallCoinPricesComponent', () => {
  let component: OverallCoinPricesComponent;
  let fixture: ComponentFixture<OverallCoinPricesComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ OverallCoinPricesComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(OverallCoinPricesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
