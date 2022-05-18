package game.scenes.carrot.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import engine.components.Spatial;
	
	import game.ui.popup.Popup;
	
	public class VentMap extends Popup
	{
		public function VentMap()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/carrot/shared/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("ventmap.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
	 		super.screen = super.getAsset("ventmap.swf", true) as MovieClip;
			super.screen.content.tfHeader.text = "Vent System Schematic";
			var placeMarker:MovieClip = MovieClip( super.screen.content.placeMarker );
			
			this.fitToDimensions(this.screen.content);
			
			loadCloseButton();
				
			if( super.shellApi.sceneName == "Vent" )
			{
				var playerSpatial:Spatial = shellApi.player.get(Spatial);
				trace ("[VentMap] playerSpatial.x:" + playerSpatial.x)
				trace ("[VentMap] playerSpatial.y:" + playerSpatial.y)
				
				var newX:Number = playerSpatial.x * .1485  + 20;
				var newY:Number	= playerSpatial.y * .1485 + 74;
					
				placeMarker.x = newX;
				placeMarker.y = newY;
			}
			else placeMarker.visible = false;
			
			super.loaded();
		}

	}
}
