package game.scenes.con2.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.scenes.con2.Con2Events;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	
	public class Phone extends Popup
	{
		private var closeUps:Entity;
		private var closeUpsToolTip:ToolTip;
		private var closeUpsInteraction:Interaction;
		protected var _events:Con2Events;
		
		public function Phone(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			darkenAlpha = .5;
			darkenBackground = true;
			groupPrefix = "scenes/con2/shared/popups/";
			super.init(container);
			load();
		}
		
		override public function load():void
		{
			loadFiles(["phone.swf"], false, true, loaded);
		}
		
		override public function loaded():void
		{
			screen = getAsset("phone.swf", true) as MovieClip;
			screen.x *= shellApi.viewportWidth / 960;
			screen.y *= shellApi.viewportHeight / 640;
			loadCloseButton();
			super.loaded();
			
			_events = shellApi.islandEvents as Con2Events;
			
			if (this.shellApi.checkEvent( _events.OMEGON_MASK_PHOTO )){
				addInteraction( "icon1", showCloseUp );
			}else{
				this.screen.getChildByName("icon1").visible = false;
			}
			
			if( this.shellApi.checkEvent( _events.OMEGON_BODY_PHOTO )){
				addInteraction( "icon2", showCloseUp );
			}else{
				this.screen.getChildByName("icon2").visible = false;
			}
			
			if( this.shellApi.checkEvent( _events.OMEGON_CAPE_PHOTO )){
				addInteraction( "icon3", showCloseUp );
			}else{
				this.screen.getChildByName("icon3").visible = false;
			}
			
			setupCloseUps();
		}
		
		private function setupCloseUps():void {
			closeUps = ButtonCreator.createButtonEntity(MovieClip(this.screen.getChildByName( "closeUps" )), this);
			closeUps.get(Timeline).gotoAndStop(1);
			closeUpsToolTip = closeUps.get(ToolTip);
			closeUps.remove(ToolTip);
			closeUps.get(Display).visible = false;
			
			closeUpsInteraction = InteractionCreator.addToEntity( closeUps, [ InteractionCreator.CLICK ]);
		}
		
		private function addInteraction( asset:String, handler:Function ):void
		{
			var clip:MovieClip = this.screen.getChildByName( asset );
			var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( asset )).add( new Sleep( false, false ));
			
			ToolTipCreator.addToEntity( entity ); 
			
			var interaction:Interaction = InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			interaction.click.add( handler );
		}
		
		private function showCloseUp(entity:Entity):void {
			switch(entity.get(Id).id) {
				case "icon1":
					closeUps.get(Timeline).gotoAndStop(0);
					break;
				case "icon2":
					closeUps.get(Timeline).gotoAndStop(1);
					break;
				case "icon3":
					closeUps.get(Timeline).gotoAndStop(2);
					break;
			}
			closeUps.get(Display).visible = true;
			closeUps.add(closeUpsToolTip);
			closeUpsInteraction.click.addOnce( closeCloseUps );
		}
		
		private function closeCloseUps(entity:Entity):void {
			closeUps.remove(ToolTip);
			closeUps.get(Display).visible = false;
		}
	}
}