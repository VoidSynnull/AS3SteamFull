package game.scenes.lands.shared.ui {

	/**
	 * 
	 * displays the player's current tile inventory counts.
	 * 
	 */
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.scenes.lands.shared.classes.LandInventory;
	import game.scenes.lands.shared.classes.ResourceType;
	import game.scenes.lands.shared.components.BarComponent;
	import game.scenes.lands.shared.tileLib.classes.LandProgress;

	public class LandInventoryView {

		private var myPane:MovieClip;

		private var myInventory:LandInventory;

		private var progress:LandProgress;

		public var levelPct:Number = 0;

		public function LandInventoryView( group:Group, clip:MovieClip, inventory:LandInventory, progress:LandProgress ) {

			this.myPane = clip;

			this.progress = progress;

			this.myInventory = inventory;

			this.myInventory.onUpdate.add( this.updateCollectible );

			var e:Entity = new Entity()
			.add( new BarComponent( clip.levelBar, this, "levelPct", 1 ), BarComponent );
			group.addEntity( e );

			this.refresh();

		} //

		public function refresh():void {

			var poptanium:int = this.myInventory.getResourceCount( "poptanium" );

			var fld:TextField = this.myPane.fldPoptanium;
			fld.text = poptanium.toString();

			//var levelBar:MovieClip = this.myPane.levelBar;
			
			this.levelPct = this.progress.getProgressPercent( poptanium );

			/*var types:Dictionary = this.myInventory.getResources();
			var fld:TextField;

			for each ( var type:ResourceType in types ) {

				fld = this.myPane[ "fld" + type.name ];
				if ( fld ) {
					fld.text = type.count.toString();
				} //

			} //

			var levelBar:MovieClip = this.myPane.levelBar;*/

		} //

		public function updateCollectible( type:ResourceType ):void {

			if ( type.type != "poptanium" ) {
				return;
			}

			var fld:TextField = this.myPane.fldPoptanium;
			fld.text = type.count.toString();

		//	var levelBar:MovieClip = this.myPane.levelBar;

			this.levelPct = this.progress.getProgressPercent( type.count );

			/*var fld:TextField = this.myPane[ "fld" + type.name ];
			if ( fld ) {
				fld.text = type.count.toString();
			} //*/

		} //

	} // class

} // package