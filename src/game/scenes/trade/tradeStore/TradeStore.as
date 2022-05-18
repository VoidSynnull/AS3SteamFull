package game.scenes.trade.tradeStore
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Dialog;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.scenes.trade.TradeEvents;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.util.EntityUtils;
	
	public class TradeStore extends PlatformerGameScene
	{
		public function TradeStore()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/trade/tradeStore/";
			
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
			_events = super.events as TradeEvents;
			
			super.shellApi.eventTriggered.add( eventTriggers );
			
			var entity:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "feed"] );
			InteractionCreator.addToEntity( entity,  [ InteractionCreator.CLICK ]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.add( triggerAskForFeed );
			entity.add( sceneInteraction );
			
			entity.add( new Id( "feed"));
			
			ToolTipCreator.addUIRollover( entity, ToolTipType.CLICK );
		}
		
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var dialog:Dialog;
			var entity:Entity = super.getEntityById( "clerk" );
	
			dialog = entity.get( Dialog );
			if( event == _events.ASK_FOR_FEED )
			{
				dialog.sayById( "ask_for_feed" );
			}
		}
		
		private function triggerAskForFeed( ...args ):void
		{
			super.shellApi.triggerEvent( _events.ASK_FOR_FEED );
		}
		
		private var _events:TradeEvents;
	}
}


