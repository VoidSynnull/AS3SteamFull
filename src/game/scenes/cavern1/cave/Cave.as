package game.scenes.cavern1.cave
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.data.game.GameEvent;
	import game.scenes.cavern1.shared.Cavern1Scene;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	
	public class Cave extends Cavern1Scene
	{
		public function Cave()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern1/cave/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_stanley = getEntityById("stanley");
			_tentPan = EntityUtils.createSpatialEntity(this, _hitContainer["tentPan"]);
			
			setupBats();
			showTour();
		}
		
		override protected function onEventTriggered(event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == GameEvent.GET_ITEM + cavern1.ELK_ANTLERS)
			{
				_stanley.get(Dialog).sayById("got_antlers");
			}
		}
		
		private function showTour():void
		{
			var hasBelt:Boolean = shellApi.checkHasItem(cavern1.MAGNETIC_BELT);
			
			if(!hasBelt)player.get(CharacterMotionControl).maxVelocityX = 200;
			
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.lockInput = !hasBelt;
			
			actionChain.addAction(new MoveAction(_stanley, new Point(1150, 960), new Point(25, 80), 3000)).noWait = true;
			actionChain.addAction(new CallFunctionAction(lowerStanleySpeed));
			actionChain.addAction(new MoveAction(player, new Point(1060, 960), new Point(25, 80), 3000)).noWait = true;
			actionChain.addAction(new TalkAction(_stanley, "tour_start", false, "rumors"));
			if(!hasBelt)actionChain.addAction(new PanAction(_tentPan, .1));
			actionChain.addAction(new WaitAction(3));
			actionChain.addAction(new PanAction(player));
			actionChain.addAction(new TalkAction(_stanley, "apartment", false, "look_around"));
			actionChain.execute();
		}
		
		private function lowerStanleySpeed():void
		{
			_stanley.get(CharacterMotionControl).maxVelocityX = 200;
		}
		
		private function setupBats():void
		{
			for(var i:int = 0; i < NUM_BATS; i++)
			{
				this.convertContainer(_hitContainer["bat"+i], PerformanceUtils.defaultBitmapQuality + .5);
			}
		}
		
		private const NUM_BATS:int = 5;
		private var _stanley:Entity;
		private var _tentPan:Entity;
	}
}