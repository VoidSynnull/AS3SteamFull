package game.scenes.nightWatch
{
	import game.scenes.nightWatch.adGroundH28.AdGroundH28;
	import game.scenes.nightWatch.backroom.Backroom;
	import game.scenes.nightWatch.clothingStore.ClothingStore;
	import game.scenes.nightWatch.comingSoon.ComingSoon;
	import game.scenes.nightWatch.common.Common;
	import game.scenes.nightWatch.costumeStore.CostumeStore;
	import game.scenes.nightWatch.electronicsStore.ElectronicsStore;
	import game.scenes.nightWatch.gadgetStore.GadgetStore;
	import game.scenes.nightWatch.giftStore.GiftStore;
	import game.scenes.nightWatch.mainStreet.MainStreet;
	import game.scenes.nightWatch.mallLeft.MallLeft;
	import game.scenes.nightWatch.mallMiddle.MallMiddle;
	import game.scenes.nightWatch.mallRight.MallRight;
	import game.scenes.nightWatch.managersOffice.ManagersOffice;
	import game.scenes.nightWatch.mattressStore.MattressStore;
	import game.scenes.nightWatch.parkingLot.ParkingLot;
	import game.scenes.nightWatch.petStore.PetStore;
	import game.scenes.nightWatch.printShop.PrintShop;
	import game.scenes.nightWatch.securityOffice.SecurityOffice;
	import game.scenes.nightWatch.sluggersStore.SluggersStore;
	import game.scenes.nightWatch.sluggersStoreTrashed.SluggersStoreTrashed;
	import game.scenes.nightWatch.sportsStore.SportsStore;
	import game.scenes.nightWatch.tanningSalon.TanningSalon;
	import game.scenes.nightWatch.toyStore.ToyStore;
	import game.scenes.nightWatch.vent.Vent;
	import game.data.island.IslandEvents;

	public class NightWatchEvents extends IslandEvents
	{
		public function NightWatchEvents()
		{
			super();
			super.scenes = [AdGroundH28, Backroom, ClothingStore, ComingSoon, CostumeStore, Common, ElectronicsStore, GadgetStore, GiftStore, MainStreet,
								MallLeft,MallMiddle,MallRight,ManagersOffice,MattressStore,ParkingLot,PetStore,PrintShop,SecurityOffice,SluggersStore,
								SluggersStoreTrashed,SportsStore,TanningSalon,ToyStore,Vent];
		}
	}
}