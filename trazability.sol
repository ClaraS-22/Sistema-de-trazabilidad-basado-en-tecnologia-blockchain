// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Product is ERC1155 {

    address private admin;


    uint256 private currTokenID;
    uint256 private currCategoryID;


    struct category {
        uint256[] isAncestor;
        uint256[] parents;
        uint256[] children;
        string name;
    }
    
    struct product { 
        bool active;
        bool isReplacement;
        bool isAddOn;

        address owner;

        uint256 productCategory;
        uint256 replacementFor;
        uint256 replacementPiece;
        uint256 amountLeft;

        address[] previousOwners;
        uint256[] parents;
        uint256[] children;
        uint256[] isDescendant;

        string name;
        string description;
    }

    mapping (address => bool) private users;
    mapping (uint256 => category) private categories;
    mapping (uint256 => product) private products;

    modifier onlyUser (address user) {
        require(users[user], "01"); // No eres usuario 
        _;
    }

    
    modifier sameAddress(address add1, address add2){
        require(add1 == add2, "02");
        _;
    }

    modifier validCategory (string memory name) {
        require(bytes(name).length > 0, "03"); // categoria no valida
        _;
    }
    modifier isActive (uint256 id) { 
     
        require(products[id].active, "04"); // Producto no activo
        _;
    }

    modifier enoughProduct (uint256 productID, uint256 amount) {
        require(products[productID].amountLeft >= amount, "05"); // No queda suficiente producto
        _;
    }

   function extendBitmap(uint256[] storage arr, uint256 val) internal {
        if((arr.length <= val/256)) {
            for(uint256 i = arr.length; i < val/256 + 1; i++){
                arr.push(0);
            }
        }
    }

    modifier canBeProductChild (uint256 product1, uint256 product2) {
        extendBitmap(products[product1].isDescendant, product2);
        require( and(products[product1].isDescendant[product2 / 256], product2) == 0, "06"); //Es hijo
        _;
    }

    modifier canBeCategoryParent (uint256 product1, uint256 product2) { 
        extendBitmap(categories[product1].isAncestor, product2);
        require( and(categories[product1].isAncestor[product2 / 256], product2) == 0, "07"); // es padre
        _;
    }

    modifier isDirectChildCategory (uint256 cat1, uint256 cat2) {
        bool isDirectChild = false;

        for(uint256 i = 0; i < categories[cat1].children.length; i++){
            if(categories[cat1].children[i] == cat2){
                isDirectChild = true;
            }
        }

        require(isDirectChild, "08");
        _;

    }  // Añadir a unir productos

    constructor () ERC1155("") {
        admin = msg.sender;
        users[msg.sender] = true;
        currTokenID = 0;
        currCategoryID = 0;
    }

    // TOKENS
    function and(uint256 num, uint256 tokenID) internal pure returns(uint256) {
        return num & (1 << (256 - (tokenID % 256)));
    }
    function or(uint256 num, uint256 tokenID) internal pure returns(uint256){
       return num | (1 << (256 - (tokenID % 256)));
    }

    function createToken (uint256 categoryID,uint256 amountTokens,string calldata name, string calldata description, uint256 amountLeft) 
    public 
    onlyUser(msg.sender) validCategory(categories[categoryID].name) 
    returns(uint256[] memory) 
    {
        
        require(amountTokens <= 100, "09" ); //demasiados token

        product storage newProduct = products[currTokenID];

        uint256[] memory tokenIDs = new uint256[](amountTokens);

        newProduct.active = true;
        newProduct.isAddOn = false;
        newProduct.isReplacement = false;
        newProduct.owner = msg.sender;
        newProduct.amountLeft = amountLeft;
        newProduct.productCategory = categoryID;
        newProduct.isDescendant.push(0);
        newProduct.name = name;
        newProduct.description = description;
       
        for(uint256 i=0; i < amountTokens; ++i) {
            tokenIDs[i] = currTokenID;
            products[currTokenID] = newProduct;
            unchecked { ++currTokenID; }
        }

        if(amountTokens >= 1) {
            _mintBatch(msg.sender, tokenIDs, new uint256[](amountTokens), "");
        }
        else {
            _mint(msg.sender, tokenIDs[0], 0,"");
        }

        return tokenIDs;
    }

    function deleteProduct (uint256 tokenID) 
    public 
    onlyUser(msg.sender) 
    isActive(tokenID) 
    sameAddress(msg.sender, products[tokenID].owner) 
    {
        products[tokenID].active = false;
    } 


    function getProduct (uint256 tokenID) public view  returns(product memory )  { 
        
        return(products[tokenID]); 
    }

    // CREATE PRODUCT GRAPH

    function joinProduct (uint256 childID, uint256 parentID, uint256 amount)
     public 
     onlyUser(msg.sender)
     isActive(childID) isActive(parentID) 
     enoughProduct(childID, amount) 
     isDirectChildCategory(products[parentID].productCategory, products[childID].productCategory)
     { 

        require(products[parentID].parents.length == 0, "10"); // Producto ya acabado no puede tener más componentes

        unchecked {products[childID].amountLeft -= amount; }
        products[childID].parents.push(parentID);
        products[parentID].children.push(childID);

        uint256 len;
        if(products[childID].isDescendant.length < products[parentID].isDescendant.length){
            len = products[childID].isDescendant.length;
        }
        else {
            len = products[parentID].isDescendant.length;

            for(uint256 i = len; i < products[childID].isDescendant.length; ++i){
                products[parentID].isDescendant.push(products[childID].isDescendant[i]);
            }
        }

        for(uint256 i = 0; i < len; ++i){
            products[parentID].isDescendant[i] = products[parentID].isDescendant[i] | products[childID].isDescendant[i];
        }

        if(products[parentID].isDescendant.length < (childID/256)) { 
            for(uint256 i = products[parentID].isDescendant.length; i < (childID/256); ++i){
                products[parentID].isDescendant.push(0);
            }
            products[parentID].isDescendant.push(or(0,childID));
        }
        else {
            products[parentID].isDescendant[childID/256] = or(products[parentID].isDescendant[childID/256],childID);
            
        }
    }

    function replaceProduct (uint256 parentID, uint256 childID, uint256 replacementID,uint256 amount) 
    public 
    onlyUser(msg.sender)
    isActive(replacementID) isActive(childID) isActive(parentID) 
    enoughProduct(replacementID, amount) 
    canBeProductChild(parentID, replacementID)
    {
       
        require((products[childID].productCategory == products[replacementID].productCategory), "11"); //La pieza que se esta intendando reemplazar no es compatible con la original

        unchecked {products[replacementID].amountLeft -= amount;}
        products[childID].active = false;
        products[replacementID].isReplacement = true; 
        products[childID].replacementPiece = replacementID;
        products[replacementID].replacementFor = childID;
        products[replacementID].parents = products[childID].parents;
   
    }

    function addOn (uint256 parentID, uint256 addOnPiece, uint256 amount)
    public 
    onlyUser(msg.sender) 
    isActive(addOnPiece) isActive(parentID) 
    enoughProduct(addOnPiece, amount)
    canBeProductChild(parentID, addOnPiece) 
    canBeCategoryParent(products[parentID].productCategory, products[addOnPiece].productCategory)
    {   

        unchecked { products[addOnPiece].amountLeft -= amount;  }    
        products[addOnPiece].isAddOn = true; 
        products[parentID].isDescendant[addOnPiece/256] = or(products[parentID].isDescendant[addOnPiece/256] ,addOnPiece);
        products[parentID].children.push(addOnPiece);
        products[addOnPiece].parents.push(parentID);
        

    }

    //CATEGORIES 

    function addCategory (uint256 parentID, uint256 childID)
     public 
     sameAddress(msg.sender, admin) 
     validCategory(categories[parentID].name) validCategory(categories[childID].name)
     canBeCategoryParent(parentID, childID){

        categories[parentID].children.push(childID);
        categories[childID].parents.push(parentID);

        uint256 len;
        if(categories[parentID].isAncestor.length < categories[childID].isAncestor.length){
            len = categories[parentID].isAncestor.length;
        }
        else {
            len = categories[childID].isAncestor.length;

            for(uint256 i = len; i < categories[childID].isAncestor.length; ++i){
                categories[childID].isAncestor.push(categories[parentID].isAncestor[i]);
            }
        }

        for(uint256 i = 0; i < len; ++i){
            categories[childID].isAncestor[i] = categories[childID].isAncestor[i] | categories[parentID].isAncestor[i];
        }

        if(categories[childID].isAncestor.length <= (parentID/256)) { 
            for(uint256 i = categories[childID].isAncestor.length; i < (parentID/256); ++i){
                categories[childID].isAncestor.push(0);
            }
            categories[childID].isAncestor.push(or(0,parentID));
        }
        else {
            categories[childID].isAncestor[parentID/256] = or(categories[childID].isAncestor[parentID/256], parentID);
        }
    }

    function createCategory (string calldata name)                
    public 
    sameAddress(msg.sender,admin) validCategory(name)
    returns (uint256 catID) {
        catID = currCategoryID;
        categories[currCategoryID].isAncestor.push(0);
        categories[currCategoryID].name = name;
       unchecked {++ currCategoryID; }
        return(catID);
    }

    function getCategory (uint256 id) public view onlyUser(msg.sender) 
    validCategory( categories[id].name) 
    returns (uint256[] memory, uint256[] memory, uint256[] memory, string memory) 
    {
        return (categories[id].parents, categories[id].children, categories[id].isAncestor, categories[id].name);
    }

    // USERS

    function addUser (address userAddress) public sameAddress(msg.sender, admin) {
        require(!users[userAddress] , "12"); // Ya existe el usuario

        users[userAddress] = true;
    }

    function deleteUser (address userAddress) public sameAddress(msg.sender, admin) onlyUser(userAddress) {
        users[userAddress] = false;
    }

    // TRANSFER OWNER

   function safeBatchTransferFrom( address from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) public override onlyUser(msg.sender) onlyUser(to) sameAddress(msg.sender, from) { //
        super.safeBatchTransferFrom(from, to, ids, values, data);
        
        for(uint256 i = 0; i < ids.length; ++i){
            require(products[ids[i]].owner == msg.sender, "13"); // No eres el owner del producto
            products[ids[i]].previousOwners.push(products[ids[i]].owner); 
            products[ids[i]].owner = to;
        } 
    } 

   function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public override onlyUser(msg.sender) onlyUser(to) sameAddress(msg.sender, from) sameAddress(msg.sender, products[id].owner){
        super.safeTransferFrom(from, to, id, value, data);
    
        products[id].previousOwners.push(products[id].owner); 
        products[id].owner = to;
        
    }
}