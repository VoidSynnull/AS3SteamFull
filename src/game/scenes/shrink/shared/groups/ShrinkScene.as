package game.scenes.shrink.shared.groups
{
	import flash.utils.Dictionary;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.item.UseItemData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.shrink.ShrinkEvents;
	import game.util.TweenUtils;
	
	public class ShrinkScene extends PlatformerGameScene
	{
		public var shrink:ShrinkEvents = new ShrinkEvents();
		public var useableItems:Dictionary;
		
		public var carGroup:CarGroup;
		public var grapeGroup:GrapeGroup;
		public var carryGroup:CarryGroup;
		
		public function ShrinkScene()
		{
			super();
		}
		
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			carryGroup = addChildGroup(new CarryGroup()) as CarryGroup;
			setUpUseData();
			setUpCar();
			setUpGrape();
			
			super.loaded();
		}
		
		public function setUpGrape():void
		{
			grapeGroup = addChildGroup(new GrapeGroup(_hitContainer, this)) as GrapeGroup;
		}
		
		public function setUpCar():void
		{
			carGroup = addChildGroup(new CarGroup(_hitContainer, this)) as CarGroup;
		}
		
		public function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var data:UseItemData = useableItems[event];
			if(data != null)
				data.useItem(this);
		}
		
		public function setUpUseData():void
		{
			shellApi.eventTriggered.add(onEventTriggered);
			useableItems = new Dictionary();
			useableItems[shrink.THUMB_DRIVE] = new UseItemData(useThumbDrive,false,shrink.NO_POINT+shrink.THUMB_DRIVE);
			useableItems[shrink.TORN_PAGE] = new UseItemData(useTornPage,false,shrink.NO_POINT+shrink.TORN_PAGE);
			useableItems[shrink.BLANK_PAPER] = new UseItemData(useBlankPaper,false,shrink.NO_POINT+shrink.BLANK_PAPER);
			useableItems[shrink.DIARY_KEY] = new UseItemData(useDiaryKey,false,shrink.NO_POINT+shrink.DIARY_KEY);
			var useData:UseItemData = new UseItemData(useScrewDriver,false,shrink.NO_POINT+shrink.SCREW_DRIVER,shrink.CAR_HAS_BATTERY, shrink.NO_POINT+shrink.SCREW_DRIVER, false, "car", 500);
			useData.minTargetDelta.y = 100;
			useableItems[shrink.SCREW_DRIVER] = useData;
			useData = new UseItemData(useBattery, false, shrink.NO_POINT + shrink.BATTERY, null, null, true, "car", 300);
			useData.minTargetDelta.y = 100;
			useableItems[shrink.BATTERY] = useData;
		}
		
		public function useTornPage():void{}
		
		public function useThumbDrive():void{}
		
		public function useBlankPaper():void{}
		
		public function useDiaryKey():void{}
		
		public function useScrewDriver():void
		{
			TweenUtils.entityTo(getEntityById("car_hatch"),Spatial,1,{rotation:15});
		}
		
		public function useBattery():void
		{
			Display(getEntityById("car_battery").get(Display)).visible = true;
			shellApi.removeItem(shrink.BATTERY);
			
			shellApi.triggerEvent("place_battery");
			
			shellApi.completeEvent(shrink.CAR_HAS_BATTERY);
			TweenUtils.entityTo(getEntityById("car_hatch"),Spatial,1,{rotation:0});
		}
	}
}