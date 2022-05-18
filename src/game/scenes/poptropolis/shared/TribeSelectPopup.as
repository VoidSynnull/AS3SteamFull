package game.scenes.poptropolis.shared {

	import com.greensock.easing.Back;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.data.profile.TribeData;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TribeUtils;
	
	import org.osflash.signals.Signal;

	public class TribeSelectPopup extends Popup {

		/**
		 * User selects a tribe and THEN presses start to verify.
		 * This is the tribe which was last selected.
		 */
		private var _selectedTribe:game.data.profile.TribeData;

		private var _popupFileName:String;
		private var _useCloseButton:Boolean = false;

		private var _tribeGlow:MovieClip;
		private var _labelBox:MovieClip;

		private var _tribeButtons:Vector.<Entity>
		private var _btnStart:Entity;

		/**
		 * Returns the Tribe component of the selected tribe.
		 */
		public var onTribeSelected:Signal;

		/**
		 * Tribe popup might come up when input is locked. Use this to restore it afterwards.
		 */
		private var inputRestore:Boolean;

		public function TribeSelectPopup( fileName:String, container:DisplayObjectContainer=null ) {

			super( container );
			this.screenAsset = fileName;
			this.onTribeSelected = new Signal( game.data.profile.TribeData );

		} //

		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {

			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.startPos = new Point( 0, -super.shellApi.viewportHeight );
			super.transitionIn.endPos = new Point( 0, 0 );
			super.transitionIn.ease = Back.easeOut;
			super.transitionIn.duration = .8;
			super.transitionOut = super.transitionIn.duplicateSwitch(Back.easeIn);
			super.transitionOut.duration = .8;
			super.darkenBackground = true;

			super.init( container );
			super.load();

		} //

		// all assets ready
		override public function loaded():void {

			super.loaded();
			
			this.centerWithinDimensions(this.screen.content);

			this.initScreen();

			this.inputRestore = SceneUtil.getInput( this ).lockInput;

			// If the input is frozen for some reason, unfreeze it.
			SceneUtil.lockInput( this, false );

			if ( _useCloseButton ) {
				super.loadCloseButton();
			}

		} //

		private function initScreen():void {

			this._tribeGlow = this.screen.content.tribeGlow;
			this._tribeGlow.visible = false;
			this._tribeGlow.mouseEnabled = false;
			this._tribeGlow.enabled = false;

			this._labelBox = this.screen.content.labelBox;
			this._labelBox.visible = false;
			this._labelBox.mouseEnabled = false;
			this._labelBox.mouseChildren = false;
			this._labelBox.enabled = false;

			this._labelBox.fldLabel.mouseEnabled = false;
			this._labelBox.fldLabel.autoSize = TextFieldAutoSize.CENTER;
			this._labelBox.fldLabel.selectable = false;
			this._labelBox.fldLabel = TextUtils.convertText( _labelBox.fldLabel, new TextFormat( "CreativeBlock BB" ) );

			this._tribeButtons = new Vector.<Entity>;

			var i:int = 0;
			var btnEntity:Entity;
			var interaction:Interaction;
			var btnClip:MovieClip = this.screen.content[ "btn"+i ];
			while ( btnClip ) {

				btnEntity = ButtonCreator.createButtonEntity( btnClip, this, this.selectTribeClicked, null ); 
				Button( btnEntity.get( Button ) ).value = TribeUtils.getTribeDataByIndex( i );
				interaction = btnEntity.get( Interaction );
				interaction.over.add( this.tribeRollOver );
				interaction.out.add( this.tribeRollOut );

				this._tribeButtons.push( btnEntity );
				i++;
				btnClip = this.screen.content[ "btn"+i];

			} // end-while.

			btnClip = this.screen.content["btnStart"] as MovieClip;
			this._btnStart = ButtonCreator.createButtonEntity( btnClip, this, this.startButtonClicked, null ); 
			Button(_btnStart.get(Button)).active = false;	// button is inactive until a tribe has been selected

			TextUtils.refreshText( MovieClip(btnClip.tf_clip).tf, "Diogenes" );
			btnClip.mouseChildren = false;

		} //

		/**
		 * Go with the currently selected entity.
		 */
		private function startButtonClicked( startBtn:Entity ):void {

			if ( this._selectedTribe == null ) {
				return;
			}

			this.disableSelect();
			TribeUtils.setPlayerTribe( this._selectedTribe.id, super.shellApi, true, this.onTribeSet );
		}

		private function onTribeSet( tribeValue:* = null ):void 
		{
			trace( this,":: onTribeSet : set to value: " + _selectedTribe.id );
			SceneUtil.lockInput( this, this.inputRestore );
			this.onTribeSelected.dispatch( _selectedTribe );
			this.close();
		}

		private function selectTribeClicked( btn:Entity ):void {

			var display:MovieClip = btn.get( Display ).displayObject as MovieClip;

			this._tribeGlow.x = this._labelBox.x = display.x;
			this._tribeGlow.y = this._labelBox.y = display.y;

			this._tribeGlow.visible = this._labelBox.visible = true;

			this._selectedTribe = Button( btn.get( Button ) ).value as game.data.profile.TribeData

			Button(_btnStart.get(Button)).active = true;

		} //

		private function tribeRollOver( btn:Entity ):void {

			var display:MovieClip = btn.get( Display ).displayObject as MovieClip;

			this._labelBox.x = display.x;
			this._labelBox.y = display.y;
			this._labelBox.visible = true;

			var tribeData:game.data.profile.TribeData = Button( btn.get( Button ) ).value as game.data.profile.TribeData

			var fld:TextField = this._labelBox.fldLabel;
			fld.text = tribeData.name;
			this._labelBox.box.width = fld.textWidth + 20;

		} //

		private function tribeRollOut( btn:Entity ):void {

			_labelBox.visible = false;	// TODO :: tribeRollOut is occasionally firing after tribeRollOver is triggered, order of operations issue with Interaction

		} //

		/**
		 * Disable all selection capabilities - after user presses start, mainly.
		 * Removing the Interaction components themselves, so can't be easily
		 * undone.
		 */
		private function disableSelect():void {

			this._btnStart.remove( Interaction );

			for( var i:int = this._tribeButtons.length-1; i >= 0; i-- ) {
				this._tribeButtons[i].remove( Interaction );
			}

		} //

		override public function destroy():void {

			this.onTribeSelected.removeAll();
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();

		} //

	}

} // package