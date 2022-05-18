package game.scenes.backlot.shared.popups
{
	import com.greensock.easing.Back;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.data.TimedEvent;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class Clapboard extends Popup
	{
		private var turner:Entity;
		private var clapper:Entity;
		
		private var scene:int;
		private var take:int;
		
		public function Clapboard(container:DisplayObjectContainer=null, scene:int = 1, take:int = 0)
		{
			super(container);
			this.scene = scene;
			this.take = take;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.pauseParent = false;
			super.darkenBackground = false;
			super.autoOpen = false;
			super.groupPrefix = "scenes/backlot/shared/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["clapboard.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{
	 		this.screen = super.getAsset("clapboard.swf", true) as MovieClip;
			
			var turnerClip:MovieClip = screen.content.turner;
			
			turnerClip.scene.text = "" + scene;
			turnerClip.take.text = "" + take;
			
			this.turner = EntityUtils.createSpatialEntity(this, turnerClip);
			var tween:Tween = new Tween();
			this.turner.add(tween);
			
			var spatial:Spatial = this.turner.get(Spatial);
			spatial.rotation = -90;
			
			this.clapper = EntityUtils.createSpatialEntity(this, this.screen.content.turner.clapper);
			this.clapper.add(new Tween());
			
			super.loaded();
			
			super.open();
			
			tween.to(spatial, 1.5, {rotation:0, ease:Back.easeInOut, onComplete:this.clapperUp});
		}
		
		private function clapperUp():void
		{
			var tween:Tween = this.clapper.get(Tween);
			tween.to(this.clapper.get(Spatial), 0.5, {rotation:-40, onComplete:this.clapperDown});
		}
		
		private function clapperDown():void
		{
			var tween:Tween = this.clapper.get(Tween);
			tween.to(this.clapper.get(Spatial), 0.1, {rotation:0, onComplete:this.shakeTurnerDown});
		}
		
		private function shakeTurnerDown():void
		{
			var tween:Tween = this.turner.get(Tween);
			tween.to(this.turner.get(Spatial), 0.2, {rotation:-5, onComplete:this.shakeTurnerUp});
		}
		
		private function shakeTurnerUp():void
		{
			var tween:Tween = this.turner.get(Tween);
			tween.to(this.turner.get(Spatial), 0.2, {rotation:0, onComplete:this.pauseOnClapboard});
		}
		
		private function pauseOnClapboard():void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, this.spinTurner));
		}
		
		private function spinTurner():void
		{
			var tween:Tween = this.turner.get(Tween);
			tween.to(this.turner.get(Spatial), 1.5, {rotation:-90, ease:Back.easeInOut, onComplete:this.close});
		}
	}
}
