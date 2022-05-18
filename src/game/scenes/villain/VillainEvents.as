package game.scenes.villain
{
	import game.scenes.villain.adGroundH25.AdGroundH25;
	import game.scenes.villain.binaryBard1.BinaryBard1;
	import game.scenes.villain.binaryBard2.BinaryBard2;
	import game.scenes.villain.binaryBard3.BinaryBard3;
	import game.scenes.villain.blackWidow.BlackWidow;
	import game.scenes.villain.captainCrawfish.CaptainCrawfish;
	import game.scenes.villain.captainCrawfishBottle.CaptainCrawfishBottle;
	import game.scenes.villain.common.Common;
	import game.scenes.villain.drHareBottom.DrHareBottom;
	import game.scenes.villain.drHareMiddle.DrHareMiddle;
	import game.scenes.villain.drHareTop.DrHareTop;
	import game.scenes.villain.elevator.Elevator;
	import game.scenes.villain.hallway.Hallway;
	import game.scenes.villain.helicopterRide.HelicopterRide;
	import game.scenes.villain.mainStreet.MainStreet;
	import game.scenes.villain.monet.Monet;
	import game.scenes.villain.ocean.Ocean;
	import game.scenes.villain.oilControlRoom.OilControlRoom;
	import game.scenes.villain.parachute.Parachute;
	import game.scenes.villain.picasso.Picasso;
	import game.scenes.villain.prisonExterior.PrisonExterior;
	import game.scenes.villain.prisonExteriorStormy.PrisonExteriorStormy;
	import game.scenes.villain.prisonGuardRoom.PrisonGuardRoom;
	import game.scenes.villain.prisonLab.PrisonLab;
	import game.scenes.villain.prisonLabDamaged.PrisonLabDamaged;
	import game.scenes.villain.vanGogh.VanGogh;
	import game.scenes.villain.zeusBattleNY.ZeusBattleNY;
	import game.scenes.villain.zeusDay2_3.ZeusDay2_3;
	import game.scenes.villain.zeusDay2_1.ZeusDay2_1;
	import game.scenes.villain.zeusDay2_2.ZeusDay2_2;
	import game.data.island.IslandEvents;

	
	public class VillainEvents extends IslandEvents
	{
		public function VillainEvents()
		{
			super();
			super.scenes = [AdGroundH25, BinaryBard1, BinaryBard2, BinaryBard3, BlackWidow, CaptainCrawfish, CaptainCrawfishBottle, Common, DrHareBottom, DrHareMiddle, DrHareTop, Elevator, Hallway, HelicopterRide, MainStreet, Monet, Ocean, OilControlRoom, Parachute, Picasso, PrisonExterior, PrisonExteriorStormy, PrisonGuardRoom, PrisonLab, PrisonLabDamaged, VanGogh, ZeusBattleNY, ZeusDay2_1, ZeusDay2_2, ZeusDay2_3];
		}
	}
}