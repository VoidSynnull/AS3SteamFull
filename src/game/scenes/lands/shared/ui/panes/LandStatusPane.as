package game.scenes.lands.shared.ui.panes {

	/**
	 * 
	 * displays the player's current tile inventory counts.
	 * 
	 */
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import game.scenes.lands.shared.classes.LandInventory;
	import game.scenes.lands.shared.classes.ResourceType;
	import game.scenes.lands.shared.components.BarComponent;
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.tileLib.classes.LandProgress;

	public class LandStatusPane {

		private var myPane:MovieClip;

		private var myInventory:LandInventory;

		private var progress:LandProgress;

		public var levelPct:Number = 0;

		public function LandStatusPane( group:LandUIGroup, clip:MovieClip, inventory:LandInventory, progress:LandProgress ) {

			this.myPane = clip;

			this.progress = progress;

			this.progress.onLevelChanged.add( this.onLevelChanged );

			this.myInventory = inventory;
			this.myInventory.onUpdate.add( this.updateCollectible );

			var e:Entity = new Entity()
			.add( new BarComponent( clip.levelBar, this, "levelPct", 1 ), BarComponent );
			group.addEntity( e );

			this.initLifeBar( group.landGroup.getPlayer() );

			this.refresh();

		} //

		public function show():void {
			this.myPane.visible = true;
		} //

		public function hide():void {
			this.myPane.visible = false;
		} //

		private function initLifeBar( player:Entity ):void {

			var life:Life = player.get( Life ) as Life;

			// kinda a crappy way to do this.
			var bar:BarComponent = new BarComponent( this.myPane.lifeBar, life, "curLife", life.maxLife );
			player.add( bar, BarComponent );

		} //

		private function onLevelChanged( newLevel:int ):void {

			this.myPane.fldLevel.text = "Level " + newLevel;

		} //

		public function refresh():void {

			var poptanium:int = this.myInventory.getResourceCount( "poptanium" );

			var fld:TextField = this.myPane.fldPoptanium;
			fld.text = poptanium.toString();
			//var levelBar:MovieClip = this.myPane.levelBar;

			this.levelPct = this.progress.getProgressPercent( this.myInventory.getResourceCount( "experience" ) );
			this.myPane.fldLevel.text = "Level " + this.progress.curLevel;


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

			if ( type.type == "poptanium" ) {

				this.myPane.fldPoptanium.text = type.count.toString();

			} else if ( type.type == "experience" ) {

				this.levelPct = this.progress.getProgressPercent( type.count );

			} //

		} //

	} // class

} // package