package game.scenes.prison.tower.popups
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ButtonCreator;
	import game.scenes.prison.PrisonEvents;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class SafePopup extends Popup
	{
		
		private var _events:PrisonEvents;
		public var events:PrisonEvents;
		private var r1:Entity;
		private var r2:Entity;
		private var r3:Entity;
		private var l1:Entity;
		private var l2:Entity;
		private var l3:Entity;
		private var handle:Entity;
		private var handleBtn:Entity;
		public var safeOpened:Boolean = false;
		
		private var topNum:int = 4;
		private var midNum:int = 7;
		private var botNum:int = 2;
		private var topNums:Array = ["t_0", "t_1", "t_2", "t_3", "t_4", "t_5", "t_6", "t_7", "t_8", "t_9"];
		private var midNums:Array = ["m_0", "m_1", "m_2", "m_3", "m_4", "m_5", "m_6", "m_7", "m_8", "m_9"];
		private var botNums:Array = ["b_0", "b_1", "b_2", "b_3", "b_4", "b_5", "b_6", "b_7", "b_8", "b_9"];
		
		private var midPoint:Number = 735.65;
		private var leftPoint:Number = 672.4;
		private var rightPoint:Number = 798.4;
		
		public function SafePopup(container:DisplayObjectContainer = null)
		{
			super(container);
			_events = new PrisonEvents();
			
			this.id 				= "SafePopup";
			this.groupPrefix 		= "scenes/prison/tower/popups/";
			this.screenAsset 		= "safePopup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function destroy():void
		{			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			//this.transitionIn 			= new TransitionData();
			//this.transitionIn.duration 	= 0.3;
			//this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			//this.transitionIn.endPos 		= new Point(0, 0);
			//this.transitionIn.ease 		= Bounce.easeIn;
			//this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			//this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		override public function loaded():void
		{	
			super.loaded();
			
			this.events = this.shellApi.islandEvents as PrisonEvents;
			
			this.setupContent();
			this.setupButtons();
			this.setupNums();
			this.setupHandle();
			super.loadCloseButton();
		}
		
		private function onClickR1(entity:Entity):void {
			if(topNum < 9){
				topNum++;
			} else {
				topNum = 0;
			}
			positionTop();
			dialSound();
		}
		
		private function onClickL1(entity:Entity):void {
			if(topNum > 0){
				topNum--;
			} else {
				topNum = 9;
			}
			positionTop();
			dialSound();
		}
		
		private function onClickR2(entity:Entity):void {
			if(midNum < 9){
				midNum++;
			} else {
				midNum = 0;
			}
			positionMid();
			dialSound();
		}
		
		private function onClickL2(entity:Entity):void {
			if(midNum > 0){
				midNum--;
			} else {
				midNum = 9;
			}
			positionMid();
			dialSound();
		}
		
		private function onClickR3(entity:Entity):void {
			if(botNum < 9){
				botNum++;
			} else {
				botNum = 0;
			}
			positionBot();
			dialSound();
		}
		
		private function onClickL3(entity:Entity):void {
			if(botNum > 0){
				botNum--;
			} else {
				botNum = 9;
			}
			positionBot();
			dialSound();
		}
		
		private function positionTop():void {
			var i:uint;
			var entity:Entity;
			for(i=0;i<topNums.length;i++){
				entity = this.getEntityById(topNums[i]);
				if(i == topNum - 1){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = leftPoint;
					entity.get(Spatial).scaleX = .782;
				} else if(i == topNum){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = midPoint;
					entity.get(Spatial).scaleX = 1;
				} else if(i == topNum +1){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = rightPoint;
					entity.get(Spatial).scaleX = .782;
				} else if(topNum == 0 && i == 9){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = leftPoint;
					entity.get(Spatial).scaleX = .782;
				} else if(topNum == 9 && i == 0){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = rightPoint;
					entity.get(Spatial).scaleX = .782;
				} else {
					entity.get(Display).alpha = 0;
				}
			}
		}
		
		private function positionMid():void {
			var i:uint;
			var entity:Entity;
			for(i=0;i<midNums.length;i++){
				entity = this.getEntityById(midNums[i]);
				if(i == midNum - 1){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = leftPoint;
					entity.get(Spatial).scaleX = .782;
				} else if(i == midNum){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = midPoint;
					entity.get(Spatial).scaleX = 1;
				} else if(i == midNum +1){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = rightPoint;
					entity.get(Spatial).scaleX = .782;
				} else if(midNum == 0 && i == 9){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = leftPoint;
					entity.get(Spatial).scaleX = .782;
				} else if(midNum == 9 && i == 0){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = rightPoint;
					entity.get(Spatial).scaleX = .782;
				} else {
					entity.get(Display).alpha = 0;
				}
			}
		}
		
		private function positionBot():void {
			var i:uint;
			var entity:Entity;
			for(i=0;i<botNums.length;i++){
				entity = this.getEntityById(botNums[i]);
				if(i == botNum - 1){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = leftPoint;
					entity.get(Spatial).scaleX = .782;
				} else if(i == botNum){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = midPoint;
					entity.get(Spatial).scaleX = 1;
				} else if(i == botNum +1){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = rightPoint;
					entity.get(Spatial).scaleX = .782;
				} else if(botNum == 0 && i == 9){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = leftPoint;
					entity.get(Spatial).scaleX = .782;
				} else if(botNum == 9 && i == 0){
					entity.get(Display).alpha = 1;
					entity.get(Spatial).x = rightPoint;
					entity.get(Spatial).scaleX = .782;
				} else {
					entity.get(Display).alpha = 0;
				}
			}
		}
		
		private function checkCombo(entity:Entity):void {
			SceneUtil.lockInput(this, true);
			if(topNum == 6 && midNum == 4 && botNum == 0){ // open safe
				safeOpened = true;
				TweenUtils.globalTo(this, handle.get(Spatial), 0.75, {rotation:-90, ease:Sine.easeInOut, onComplete:resetHandle}, "handleOut");
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "unlocked_04.mp3" );
			} else { //fail to open safe
				TweenUtils.globalTo(this, handle.get(Spatial), 0.25, {rotation:-20, yoyo:true, repeat:3, ease:Sine.easeInOut, onComplete:resetHandle}, "handleOut");
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "lock_jiggle_01.mp3" );
			}
			
		}
		
		private function dialSound(...p):void
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "rolling_ticker_02.mp3" );
		}
		
		private function resetHandle():void {
			SceneUtil.lockInput(this, false);
			if(safeOpened) {
				shellApi.triggerEvent("opened_safe");
				close();
			}
		}
		
		private function setupHandle():void {
			handle = EntityUtils.createSpatialEntity(this, this.screen.content["handle"], this.screen.content);
			handleBtn = ButtonCreator.createButtonEntity(this.screen.content.handleBtn, this, checkCombo, null, null, null, true, true);
		}
		
		private function setupNums():void {
			var i:uint;
			var entity:Entity;
			for(i=0;i<topNums.length;i++){
				entity = EntityUtils.createSpatialEntity(this, this.screen.content["t_"+i], this.screen.content);
				entity.add(new Id("t_"+i));
				
				if(i == topNum-1 || i == topNum || i == topNum+1){
					entity.get(Display).alpha = 1;
				} else {
					entity.get(Display).alpha = 0;
				}
				
				entity = EntityUtils.createSpatialEntity(this, this.screen.content["m_"+i], this.screen.content);
				entity.add(new Id("m_"+i));
				if(i == midNum-1 || i == midNum || i == midNum+1){
					entity.get(Display).alpha = 1;
				} else {
					entity.get(Display).alpha = 0;
				}
				
				entity = EntityUtils.createSpatialEntity(this, this.screen.content["b_"+i], this.screen.content);
				entity.add(new Id("b_"+i));
				if(i == botNum-1 || i == botNum || i == botNum+1){
					entity.get(Display).alpha = 1;
				} else {
					entity.get(Display).alpha = 0;
				}
			}
			positionTop();
			positionMid();
			positionBot();
		}
		
		private function setupButtons():void {
			r1 = ButtonCreator.createButtonEntity(this.screen.content.r1, this, onClickR1, null, null, null, true, true);	
			l1 = ButtonCreator.createButtonEntity(this.screen.content.l1, this, onClickL1, null, null, null, true, true);
			r2 = ButtonCreator.createButtonEntity(this.screen.content.r2, this, onClickR2, null, null, null, true, true);	
			l2 = ButtonCreator.createButtonEntity(this.screen.content.l2, this, onClickL2, null, null, null, true, true);
			r3 = ButtonCreator.createButtonEntity(this.screen.content.r3, this, onClickR3, null, null, null, true, true);	
			l3 = ButtonCreator.createButtonEntity(this.screen.content.l3, this, onClickL3, null, null, null, true, true);
		}
		
		private function setupContent():void
		{
			this.letterbox(this.screen.content, new Rectangle(0, 0, 960, 640));
		}
	}
}