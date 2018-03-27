export class OrderBookData {
    FromCoinName: string;
    ToCoinName: string;
    Exchange: string;
    Asks: (string | number)[][];
    Bids: (string | number)[][];
    IsFrozen: string;
    Seq: number;
    Depth: number;
}
