package game.scenes.lands.lab2 {
	
	import flash.display.DisplayObjectContainer;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.lab1.Lab1;
	
	public class Lab2 extends PlatformerGameScene {
		
		public function Lab2() {
			
			super();
			
		} //
		
		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {
			
			super.groupPrefix = "scenes/lands/lab1/";
			super.init( container );
			
		} //
		
		// initiate asset load of scene specific assets.
		override public function load():void {
			
			super.load();
			
		} //
		
		// all assets ready
		override public function loaded():void {
			
			this.shellApi.loadScene(Lab1);
			
		} // loaded()
		
	} // class
	
} // package