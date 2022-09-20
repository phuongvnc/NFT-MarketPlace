# Hướng dẫn sử dụng  NFT và NFT Market Place
### 1.NFTMarketPlace.sol
- Đăng bán item trên market place thì gọi `createMarketItem(uint256 tokenId, address paymentToken, uint256 price)` với `tokenId` là id của NFT, `paymentToken` là địa chỉ contract của NFT và price là giá tiền để đăng bán NFT đó
- Muốn mua một NFT thì gọi `buyMarketItem(uint256 itemId, address paymentToken)` với `itemID` như index của NFT và `paymentToken` là địa chỉ contract của NFT. Lưu ý là function này cần truyền `ETH` lên 
### 2.NFT.sol
- Hàm khởi tạo của NFT yêu cầu các tham số  `name` tên  token , `symbol` ký hiệu token và  `_limitToken` giới hạn số lượng token
- Sau khi deploy NFT thì cần call function `setApprovalForAll(address operator, bool approved)` với `operator` là địa chỉ contract của `NFTMarketPlace` và `approved` là true.Để chấp nhận NFTMarketPlace có thể sử dụng việc transfer của các token trong NFT.
- Truyền địa chỉ của NFT qua bên MarketPlace qua function `addPaymentToken(address paymentToken_)` để xác định Market Place sẽ hỗ trợ mua bán cho token đó
- Gọi `mintNft(string memory tokenURI_)` để khởi tạo các token NFT.