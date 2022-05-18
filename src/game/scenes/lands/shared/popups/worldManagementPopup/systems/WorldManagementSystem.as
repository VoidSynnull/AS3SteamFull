package game.scenes.lands.shared.popups.worldManagementPopup.systems  {

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.popups.worldManagementPopup.WorldManagementPopup;
	import game.scenes.lands.shared.popups.worldManagementPopup.components.BubbleRealm;
	import game.scenes.lands.shared.popups.worldManagementPopup.nodes.BubbleRealmNode;
	import game.scenes.lands.shared.popups.worldManagementPopup.nodes.WorldNode;
	import game.systems.SystemPriorities;
	
	public class WorldManagementSystem extends System
	{
		private var _bubbleList:NodeList;
		private var _worldList:NodeList;

		private var bgClip:MovieClip;

		private var managementPopup:WorldManagementPopup;

		private var mouseContainer:DisplayObject;

		private var stageWidth:Number;
		private var stageHeight:Number;
		
		private var art:MovieClip;
		private var twirl:MovieClip;
		private var glow:MovieClip;
		
		public function WorldManagementSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			this._bubbleList = systemManager.getNodeList( BubbleRealmNode );
			this._worldList = systemManager.getNodeList( WorldNode );

			this.managementPopup = super.group as WorldManagementPopup;

			this.bgClip = this.managementPopup.bgClip;

			//ballSpatial = ball.entity.get(Spatial);
			this.mouseContainer = this.managementPopup.container;
			this.stageWidth = this.managementPopup.shellApi.viewportWidth;
			this.stageHeight = this.managementPopup.shellApi.viewportHeight;
		}
		
		override public function update( time:Number ):void {

			var targetX:Number = this.mouseContainer.mouseX;
			var targetY:Number = this.mouseContainer.mouseY;

			var mouseVX:Number = ( this.stageWidth/2 - targetX ) * 0.025;
			var mouseVY:Number = ( this.stageHeight/2 - targetY ) * 0.025;

			var spatial:Spatial;

			if ( this.managementPopup.selectedWorld != null) {

				spatial = this.managementPopup.selectedWorld.get( Spatial );

				targetX = spatial.x;
				targetY = spatial.y + 50;

				if ( this.managementPopup.selectedWorld.get(BubbleRealm) ){ //if selected world is a bubble, offset center up so it's visible beneath new realm pane
					targetY -= 75;
				}

				if ( this.managementPopup.zoomSelectedWorld ){
					spatial.scale += .01;
				}

				//if following selected world/bubble, then follow more closely
				mouseVX = ( this.stageWidth/2 - targetX ) * 0.05;
				mouseVY = ( this.stageHeight/2 - targetY ) * 0.05;
			}

			//move Background
			this.bgClip.x += mouseVX * 0.15;
			this.bgClip.y += mouseVY * 0.15;
			
			if ( this.bgClip.x > 0 ){
				this.bgClip.x -= this.bgClip.width / 2;
			} else if ( this.bgClip.x < (-this.bgClip.width + this.stageWidth) ) {
				this.bgClip.x += this.bgClip.width / 2;
			}
			
			if ( this.bgClip.y > 0 ) {
				this.bgClip.y -= this.bgClip.height / 2;
			}
			else if ( this.bgClip.y < -this.bgClip.height + this.stageHeight) {
				this.bgClip.y += this.bgClip.height / 2;
			}

			for( var bubbleNode:BubbleRealmNode = this._bubbleList.head; bubbleNode; bubbleNode = bubbleNode.next) {

				spatial = bubbleNode.spatial;

				spatial.x += bubbleNode.bubble.vx + mouseVX *( spatial.scaleX*0.7 );
				spatial.y += bubbleNode.bubble.vy + mouseVY *( spatial.scaleX*0.7 );
				this.checkBounds( spatial );

				var loadArrow:MovieClip = MovieClip( bubbleNode.display.displayObject["loadIcon"] );
				if (loadArrow.visible) {
					loadArrow.rotation += 5;
				}

			} // for-loop.

			for ( var worldNode:WorldNode = this._worldList.head; worldNode; worldNode = worldNode.next) {

				spatial = worldNode.spatial;
				spatial.x += worldNode.world.vx + mouseVX;
				spatial.y += worldNode.world.vy + mouseVY;
				this.checkBounds( spatial );

				var worldClip:MovieClip = worldNode.display.displayObject;
				this.art = worldClip["art"];
				this.twirl = worldClip["twirl"];
				this.glow = this.art["glow"];

				//trace( worldClip.hitTestPoint( worldClip.stage.mouseX, worldClip.stage.mouseY ) );

				this.art.scaleX = this.art.scaleY = this.twirl.scaleX = this.twirl.scaleY += ( worldNode.world.targetScale - this.art.scaleX )/4;
				// += ( worldNode.world.targetScale - this.twirl.scaleX )/4;

				if ( this.managementPopup.selectedWorld == worldNode.entity) {
					this.glow.alpha += ( 1 - this.glow.alpha )/4;
				}
				else {
					this.glow.alpha += ( 0.2 - this.glow.alpha )/4;
				}
				
				this.twirl.rotation += 2;
			}

			this.managementPopup.curInfoPane.pane.y +=
				( this.managementPopup.worldInfoTargetY - this.managementPopup.curInfoPane.pane.y )/4;

		} //

		public function initRealmWorld( e:Entity ):void {
		} //

		public function initBubbleWorld( e:Entity ):void {
		} //

		private function realmWorldLoaded( e:Entity ):void {
		} //

		private function bubbleWorldLoaded( e:Entity ):void {
		} //

		private function checkBounds(spatial:Spatial):void {

			if (spatial.x < -spatial.width/2) {
				spatial.x += this.stageWidth + spatial.width;
			}
			else if (spatial.x > this.stageWidth + spatial.width/2) {
				spatial.x -= this.stageWidth + spatial.width;
			}
			if (spatial.y < -spatial.height/2) {
				spatial.y += this.stageHeight + spatial.height;
			}
			else if (spatial.y > this.stageHeight + spatial.height/2) {
				spatial.y -= this.stageHeight + spatial.height;
			}

		} //
		
		override public function removeFromEngine( systemsManager:Engine ):void {

			systemsManager.releaseNodeList( BubbleRealmNode );
			systemsManager.releaseNodeList( WorldNode );
			this._bubbleList = null;
			this._worldList = null;
			this.managementPopup = null;

			this.art = null;
			this.twirl = null;
			this.glow = null;

		}

	} // class

} // package