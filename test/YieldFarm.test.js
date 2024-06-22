const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("YieldFarm", function () {
    let ANIToken, LPCoin1, LPCoin2, MasterChef;
    let ani, lp1, lp2, chef;
    let creator, someoneElse, anotherOne;

    beforeEach(async function () {

      [creator, someoneElse, anotherOne] = await ethers.getSigners();

        ANIToken = await ethers.getContractFactory("SobaToken"); // native token of platform
        LPCoin1 = await ethers.getContractFactory("SobaToken");
        LPCoin2 = await ethers.getContractFactory("SobaToken");
        MasterChef = await ethers.getContractFactory("YieldFarm");

        // tokens
        ani = await ANIToken.deploy("Anime Token", "ANI");
        await ani.deployed();

        lp1 = await LPCoin1.deploy("LPCoin1", "LP1", ethers.utils.parseEther("1000000"));
        await lp1.deployed();

        lp2 = await LPCoin2.deploy("LPCoin2", "LP2", ethers.utils.parseEther("1000000"));
        await lp2.deployed();

        // Yield Farm
        chef = await MasterChef.deploy(ani.address, creator.address, ethers.utils.parseEther("1000"), "100","");
        await ani.transferMinterRole(chef.address);  // transfer minter role

        // Simulating the coin registration and minting process from test_init
        await ani.connect(someoneElse).register();
        await ani.connect(anotherOne).register();

        let coinsSomeoneElse = await ani.mint(ethers.utils.parseEther("1000000"));
        await ani.connect(someoneElse).deposit(coinsSomeoneElse);

        let coinsAnotherOne = await ani.mint(ethers.utils.parseEther("1000000"));
        await ani.connect(anotherOne).deposit(coinsAnotherOne);

    });
  });

  it("Setup initial state for creator, someoneElse, anotherOne", async function() {
    await lp1.connect(someoneElse).register();
    await lp1.connect(anotherOne).register();

    let coinsLp1SomeoneElse = await lp1.mint(ethers.utils.parseEther("1000000"));
    await lp1.connect(someoneElse).deposit(coinsLp1SomeoneElse);


    let coinsLp1AnotherOne = await lp1.mint(ethers.utils.parseEther("1000000"));
    await lp1.connect(anotherOne).deposit(coinsLp1AnotherOne);

    await lp2.connect(someoneElse).register();
    await lp2.connect(anotherOne).register();

    let coinsLp2SomeoneElse


  })

  it("Add Liquidity", async function() {
    const chefAsCreator = chef.connect(creator);
    await chefAsCreator.add("1000", lp1.address,true);
    await chefAsCreator.add("1000", lp2.address,true);



  })

  it("deposit/withdraw", async function() {
    const chefAsDev = chef.connect(dev.address)

    await chefAsDev.add("1000",lp1.address, true);
  })

  // it("deposit/withdraw", async () => {

  //   await chef.connect();

  //   await chef.add("1000", lp1.address, true, { from: minter });
  //   await chef.add("1000", lp2.address, true, { from: minter });
  //   await chef.add("1000", lp3.address, true, { from: minter });

  //   await lp1.approve(chef.address, "100", { from: alice });
  //   await chef.deposit(1, "20", { from: alice });
  //   await chef.deposit(1, "0", { from: alice });
  //   await chef.deposit(1, "40", { from: alice });
  //   await chef.deposit(1, "0", { from: alice });
  //   assert.equal((await lp1.balanceOf(alice)).toString(), "1940");
  //   await chef.withdraw(1, "10", { from: alice });
  //   assert.equal((await lp1.balanceOf(alice)).toString(), "1950");
  //   assert.equal((await cake.balanceOf(alice)).toString(), "999");
  //   assert.equal((await cake.balanceOf(dev)).toString(), "100");

  //   await lp1.approve(chef.address, "100", { from: bob });
  //   assert.equal((await lp1.balanceOf(bob)).toString(), "2000");
  //   await chef.deposit(1, "50", { from: bob });
  //   assert.equal((await lp1.balanceOf(bob)).toString(), "1950");
  //   await chef.deposit(1, "0", { from: bob });
  //   assert.equal((await cake.balanceOf(bob)).toString(), "125");
  //   await chef.emergencyWithdraw(1, { from: bob });
  //   assert.equal((await lp1.balanceOf(bob)).toString(), "2000");
  // });

  // it("staking/unstaking", async () => {
  //   await chef.add("1000", lp1.address, true, { from: minter });
  //   await chef.add("1000", lp2.address, true, { from: minter });
  //   await chef.add("1000", lp3.address, true, { from: minter });

  //   await lp1.approve(chef.address, "10", { from: alice });
  //   await chef.deposit(1, "2", { from: alice }); //0
  //   await chef.withdraw(1, "2", { from: alice }); //1

  //   await cake.approve(chef.address, "250", { from: alice });
  //   await chef.enterStaking("240", { from: alice }); //3
  //   assert.equal((await cake.balanceOf(alice)).toString(), "10");
  //   await chef.enterStaking("10", { from: alice }); //4
  //   assert.equal((await cake.balanceOf(alice)).toString(), "249");
  //   await chef.leaveStaking(250);
  //   assert.equal((await cake.balanceOf(alice)).toString(), "749");
  // });

  // it("updaate multiplier", async () => {
  //   await chef.add("1000", lp1.address, true, { from: minter });
  //   await chef.add("1000", lp2.address, true, { from: minter });
  //   await chef.add("1000", lp3.address, true, { from: minter });

  //   await lp1.approve(chef.address, "100", { from: alice });
  //   await lp1.approve(chef.address, "100", { from: bob });
  //   await chef.deposit(1, "100", { from: alice });
  //   await chef.deposit(1, "100", { from: bob });
  //   await chef.deposit(1, "0", { from: alice });
  //   await chef.deposit(1, "0", { from: bob });

  //   await cake.approve(chef.address, "100", { from: alice });
  //   await cake.approve(chef.address, "100", { from: bob });
  //   await chef.enterStaking("50", { from: alice });
  //   await chef.enterStaking("100", { from: bob });

  //   await chef.updateMultiplier("0", { from: minter });

  //   await chef.enterStaking("0", { from: alice });
  //   await chef.enterStaking("0", { from: bob });
  //   await chef.deposit(1, "0", { from: alice });
  //   await chef.deposit(1, "0", { from: bob });

  //   assert.equal((await cake.balanceOf(alice)).toString(), "700");
  //   assert.equal((await cake.balanceOf(bob)).toString(), "150");

  //   await time.advanceBlockTo("265");

  //   await chef.enterStaking("0", { from: alice });
  //   await chef.enterStaking("0", { from: bob });
  //   await chef.deposit(1, "0", { from: alice });
  //   await chef.deposit(1, "0", { from: bob });

  //   assert.equal((await cake.balanceOf(alice)).toString(), "700");
  //   assert.equal((await cake.balanceOf(bob)).toString(), "150");

  //   await chef.leaveStaking("50", { from: alice });
  //   await chef.leaveStaking("100", { from: bob });
  //   await chef.withdraw(1, "100", { from: alice });
  //   await chef.withdraw(1, "100", { from: bob });
  // });

  // it("should allow dev and only dev to update dev", async () => {
  //   assert.equal((await chef.devaddr()).valueOf(), dev);
  //   await expectRevert(chef.dev(bob, { from: bob }), "dev: wut?");
  //   await chef.dev(bob, { from: dev });
  //   assert.equal((await chef.devaddr()).valueOf(), bob);
  //   await chef.dev(alice, { from: bob });
  //   assert.equal((await chef.devaddr()).valueOf(), alice);
  // });





