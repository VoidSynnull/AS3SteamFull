package game.scenes.carrot.freezer
{
	import flash.display.DisplayObjectContainer;
	import ash.core.Entity;
	
	import engine.group.TransportGroup;
	
	import game.components.render.Reflection;
	import game.components.scene.Cold;
	import game.components.scene.SceneInteraction;
	import game.scenes.carrot.CarrotEvents;
	import game.scene.template.PlatformerGameScene;
	
	public class Freezer extends PlatformerGameScene
	{
		public function Freezer()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/freezer/";
			super.init(container);
		}
				
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
			_events = super.events as CarrotEvents;
		}
		
		override public function loaded():void
		{
			SceneInteraction(super.getEntityById("interaction1").get(SceneInteraction)).reached.add(sceneInteractionTriggered);			
			super.loaded();
		
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player );
				super.shellApi.eventTriggered.add( onEventTriggered );
			}
			else
			{
				// Cold is picked up my Animations to add 'breath'
				super.player.add(new Cold());
			}
			this.setupReflection();
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if ( event == "teleport_finished" )
			{
				super.player.add(new Cold());
			}
		}
		
		private function setupReflection():void
		{
			this.player.add(new Reflection());
		}
	
		private function sceneInteractionTriggered(character:Entity, interaction:Entity):void
		{
			super.shellApi.triggerEvent( _events.SECURITY_OPEN_CLOSE );
			_securityConsole = super.addChildGroup( new SecurityConsole( super.overlayContainer )) as SecurityConsole;
		}
		
		
		private var _events:CarrotEvents;
		private var _securityConsole:SecurityConsole;
	}
}