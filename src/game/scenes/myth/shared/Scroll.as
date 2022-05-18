package game.scenes.myth.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.data.scene.characterDialog.DialogData;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterDialogGroup;
	import game.ui.popup.Popup;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	
	public class Scroll extends Popup
	{		
		public function Scroll( container:DisplayObjectContainer = null )
		{
			super( container );
		}
		
		override public function close( removeOnClose:Boolean = true, onClosedHandler:Function = null ):void
		{
			remove();
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/myth/shared/";
			super.init( container );
			
			load();
		}		
		
		override public function load():void
		{
			super.loadFiles([ "scroll.swf" ], false, true, loaded );
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.screen = super.getAsset( "scroll.swf", true ) as MovieClip;
			super.layout.centerUI( super.screen.content );
			super.shellApi.triggerEvent( "open_scroll" );
			
			characterDialogGroup = parent.getGroupById( "characterDialogGroup" ) as CharacterDialogGroup;
			setupScroll();
			
			super.loadCloseButton();
			super.loaded();
		}
		
		private function setupScroll():void
		{
			var clip:MovieClip;
			var checkBox:Entity; 
			var timeline:Timeline;
			var item:String;
			var number:int;
			
			var textField:TextField;
			var data:DialogData;
			var textFormat:TextFormat = new TextFormat( "Diogenes", 15, 0x856547, null, null, null, null, null, null, null, null, null, 2 );
			
			// pull text from xml
			data = characterDialogGroup.allDialogData[ "scroll" ][ "preface" ];
			textField =  TextUtils.refreshText( super.screen.content.preface );
			
			textField.embedFonts = true;
			textField.wordWrap = true;
			textField.height *= 2;
			textField.defaultTextFormat = textFormat;
			
			textField.text = data.dialog;
			
			for( number = 1; number < 6; number ++ )
			{
				switch( number )
				{
					case 1:
						textField =  TextUtils.refreshText( super.screen.content.item1 );
						item = "sphinxFlower";
						break;
					case 2:
						textField =  TextUtils.refreshText( super.screen.content.item2 );
						item = "minotaurRing";
						break;
					case 3:
						textField =  TextUtils.refreshText( super.screen.content.item3 );
						item = "hydraScale";
						break;
					case 4:
						textField =  TextUtils.refreshText( super.screen.content.item4 );
						item = "giantPearl";
						break;
					case 5:
						textField =  TextUtils.refreshText( super.screen.content.item5 );
						item = "cerberusWhisker";
						break;
				}
				
				data = characterDialogGroup.allDialogData[ "scroll" ][ "item" + number ];
				
				textField.embedFonts = true;
				textField.wordWrap = true;
				textField.defaultTextFormat = textFormat;
				
				textField.text = data.dialog;
				
				clip = MovieClip( MovieClip( super.screen.content ).getChildByName( "bullet" + number ));
			 	checkBox = TimelineUtils.convertClip( clip, this );
				timeline = checkBox.get( Timeline );
				timeline.paused = true;
				
				// check if player has the item
				if( super.shellApi.checkHasItem( item ))
				{
					timeline.gotoAndStop( 1 );
				}
			}
		}
		
		private var characterDialogGroup:CharacterDialogGroup;
	}
}