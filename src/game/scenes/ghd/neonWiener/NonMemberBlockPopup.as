package game.scenes.ghd.neonWiener
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	
	import game.creators.ui.ButtonCreator;
	import game.data.display.AssetData;
	import game.data.dlc.DLCContentData;
	import game.data.text.TextData;
	import game.data.text.TextStyleData;
	import game.data.ui.ButtonData;
	import game.data.ui.TransitionData;
	import game.scenes.ghd.spacePort.SpacePort;
	import game.ui.elements.PoptropicaYouTubePlayer;
	import game.ui.hud.HudPopBrowser;
	import game.ui.popup.Popup;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	
	public class NonMemberBlockPopup extends Popup
	{
		public function NonMemberBlockPopup(groupPrefix:String, container:DisplayObjectContainer=null)
		{
			super(container);
			super.groupPrefix = groupPrefix;
			
			this.pauseParent = true;
			this.darkenBackground = true;
		}
		/**
		 * Determines if demo blocker is required.
		 * @param shellApi
		 * @return - Boolean : returns true if a block is needed.
		 */
		public static function checkIslandBlock( shellApi:ShellApi ):Boolean
		{
			if( PlatformUtils.isMobileOS )		// if mobile check for purchase
			{
				// check purchased
				var dlcContent:DLCContentData = shellApi.dlcManager.getDLCContentData( shellApi.island )
				if( dlcContent != null && !dlcContent.purchased )
				{
					return true;
				}
			}
			else if ( PlatformUtils.inBrowser)	// if browser check for membership
			{
				// check if island still requires membership
				if( shellApi.islandEvents.earlyAccess && !shellApi.currentProfile.isMember )
				{
					return true;
				}
			}
			
			return false;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.shellApi.track("Demo", "DemoBlock", "Impressions", shellApi.island);
			
			transitionIn = new TransitionData();
			transitionIn.duration = .5;
			transitionIn.startPos = new Point( super.shellApi.viewportWidth/2, -super.shellApi.viewportHeight/2);
			transitionIn.endPos = new Point( super.shellApi.viewportWidth/2, super.shellApi.viewportHeight/2);
			transitionOut = transitionIn.duplicateSwitch();	// this shortcut method flips the start and end position of the transitionIn
			
			super.init(container); // creates a new groupContainer, and adds it to container
			this.load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// TODO :: may want to pull different asset for web and mobile
			var assets:Array = new Array();
			assets.push( ASSET_PATH );
			assets.push( super.groupPrefix + DATA_FILE);
			super.loadFiles( assets, true, true, this.loaded );
		}
		
		/**
		 * adds screen to groupContainer, creates a closebutton if found, dispatch ready
		 */
		override public function loaded(): void 
		{
			// setup display
			super.screen = super.getAsset( ASSET_PATH, true, true, true) as MovieClip;
			_content = MovieClip(super.screen)["content"];
			
			
			preparePopup();	// manages popup specific start up
			
			//super.centerWithinDimensions( super.screen );
			super.screen.x = super.shellApi.viewportWidth/2;
			super.screen.y = super.shellApi.viewportHeight/2;
			
			super.loadCloseButton("", this.shellApi.viewportWidth/2 + 50, -this.shellApi.viewportHeight/2 + 50);
			
			// setup data
			var blockerXML:XML = super.getData( DATA_FILE, true );
			setupContent( blockerXML );
		}
		
		/**
		 * Non-interactive elemenst finished loading.
		 * Start loading interactive elements, such as buttons and special card content
		 * @param cardItem
		 */
		private function assetLoadingComplete():void
		{
			// TODO :: Bitmap everything thus far aside from buttons?
			
			// different buttons are created depending on platform
			var btnClip:MovieClip;
			if( PlatformUtils.isMobileOS )
			{
				// setup buy button
				_content.removeChild( _content.membership_btn );
				btnClip = _content.buy_btn;
				ButtonCreator.createButtonEntity( btnClip, this, onPurchaseBtn );
				setButtonText( btnClip.text_mc.tf, BTN_BUY );
				
				// TODO :: May want to be able to play trailer at some point.
			}
			else
			{
				// TESTING :: set to true by default
				// setup membership button
				_content.removeChild( _content.buy_btn );
				btnClip = _content.membership_btn
				var entity:Entity = ButtonCreator.createButtonEntity( btnClip, this, onMembershipBtn );
				setButtonText( btnClip.tf, BTN_MEMBER );
				
				//setup video
				
				//Doesn't look like you can play YouTube videos locally. This crashes otherwise.
				if(PlatformUtils.inBrowser)
				{
					setupVideo();		// TODO :: Needs further testing
				}
			}
			
			super.groupReady();
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////////// BROWSER ONLY /////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function setupVideo():void
		{
			// setup youtube
			_youTubePlayer = new PoptropicaYouTubePlayer();
			screen.addChild(_youTubePlayer);
			_youTubePlayer.size = _videoRect;
			_youTubePlayer.videoID = _videoId;	//get this from data
			_youTubePlayer.playerReady.addOnce(onYouTubeReady);
		}
		
		private function onYouTubeReady():void {
			trace("yutoob", _youTubePlayer.percentLoaded, "percent loaded");
		}
		
		private function onMembershipBtn( entity:Entity ):void 
		{
			if (_youTubePlayer) 
			{
				_youTubePlayer.pausePlayer(true);
			}
			super.shellApi.track("Demo", "DemoBlock", "Clicks", shellApi.island);
			HudPopBrowser.buyMembership(super.shellApi, "source=POP_img_GetMembership_GHDDemoBlock-pop&medium=Display&campaign=GHDIsland");
		}
		/*
		private function checkMembership(...args):void 
		{
		shellApi.siteProxy.getMemberStatus(onMembershipResult);
		}
		
		private function onMembershipResult(result:PopResponse):void 
		{
		shellApi.siteProxy.onMemberStatus(result);
		if (_youTubePlayer) 
		{
		_youTubePlayer.destroy();
		}
		
		super.handleCloseClicked();	// NOTE :: close blocker popup? probably want to return to map
		}
		*/
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////////// MOBILE ONLY /////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function onPurchaseBtn(entity:Entity):void
		{
			// start purchase process
		}
		
		override protected function handleCloseClicked(...args):void
		{
			// return to map
			super.shellApi.loadScene( SpacePort );
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////////// CONTENT SETUP ////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function setupContent( xml:XML ):void
		{
			this._videoId = DataUtils.getString(xml.videoId);
			
			// parse xml
			var u:uint;
			if( xml.hasOwnProperty("assets"))
			{
				var xAssets : XMLList = xml.assets.asset;
				if( xAssets )
				{
					for(u= 0; u < xAssets.length(); u++)
					{
						_assetsData.push( new AssetData(xAssets[u]) );
					}
				}
			}
			if( xml.hasOwnProperty("buttons"))
			{
				var xButtons : XMLList = xml.buttons.btn;
				if( xButtons )
				{
					for(u = 0; u < xButtons.length(); u++)
					{
						_buttonData.push( new ButtonData(xButtons[u]) );
					}
				}
			}
			if( xml.hasOwnProperty("textfields"))
			{
				var xTexts : XMLList = xml.textfields.text;
				if( xTexts )
				{
					for(u = 0; u < xTexts.length(); u++)
					{
						_textData.push( new TextData(xTexts[u]));
					}
				}
			}
			
			// load assets & setup text
			loadAssets();
		}
		
		private function loadAssets():void
		{
			if( _currentElement < _assetsData.length)
			{
				var assetData:AssetData = _assetsData[ _currentElement ];
				var path:String = assetData.assetPath;
				
				if( DataUtils.validString( path ) )
				{
					super.shellApi.loadFile(shellApi.assetPrefix + path, assetLoaded, assetData);
				}
				/*
				// NOTE :: Example of how we might want to automate some of the asset path via id
				else if( assetData.id == CARD_CONTENT )	//  if card content path not specifiied use prefix
				{
				super.shellApi.loadFile(shellApi.assetPrefix + cardItem.pathPrefix + ".swf", assetLoaded, cardItem, assetData);
				}
				else if( assetData.id == CARD_BACK )	//  if card content path not specifiied use prefix
				{
				super.shellApi.loadFile(shellApi.assetPrefix + cardItem.pathPrefix.replace(cardItem.itemId, BACKGROUND) + ".swf", assetLoaded, cardItem, assetData);
				}
				*/
			}
			else	// once card assets have been loaded and added, load buttons
			{
				createText();	
			}
		}
		
		private function assetLoaded( displayObject:DisplayObjectContainer, assetData:AssetData):void
		{
			if( assetData.effectData )
			{
				if( assetData.effectData.filters.length > 0 )
				{
					displayObject.filters = assetData.effectData.filters;	//apply filters
				}
			}
			
			// TODO :: May want to place content into a specific container in popup
			_content.imageContainer.addChild( displayObject );	// add to clip that will be eventually bitmapped
			
			_currentElement++;
			loadAssets();		// recurse
		}
		
		public function createText():void
		{
			var textData:TextData;
			var tf:TextField;
			var textFormat:TextFormat;
			var styleFamily:String;
			var styleId:String;
			var styleData:TextStyleData;
			
			for (var i:int = 0; i < _textData.length; i++) 
			{
				textData = _textData[i];
				
				tf = new TextField();
				tf.embedFonts = true;
				tf.wordWrap = true;
				tf.antiAliasType = AntiAliasType.NORMAL;
				tf.text = textData.value;
				tf.mouseEnabled = false;
				if( textData.effectData != null )
				{
					tf.filters = textData.effectData.filters;
				}
				
				tf.height = ( !isNaN(textData.height) ) ? textData.height : super.screen.height;
				tf.width = ( !isNaN(textData.width) ) ? textData.width : super.screen.width * .9;
				
				// TODO :: May want to place content into a specific container in popup
				_content.base.text_container.addChild( tf );		// add to clip that will be eventually bitmapped
				
				// Position the textfields only, format gets applied after positoning
				tf.x = ( !isNaN( textData.xPos ) ) ? textData.xPos : (super.screen.width - tf.width) * .5;
				if( !isNaN( textData.yPos ) )
				{
					tf.y = textData.yPos;
				}
				else
				{
					switch (textData.id)
					{
						case TITLE:
							tf.y = 3;
							break;
						
						case DESCRIPTION:
							tf.y = 55;
							break;
						
						case PUBLIC_ACCESS:
							tf.y = 408;
							break;
					}
				}
				
				styleFamily = ( DataUtils.validString( textData.styleFamily ) ) ? textData.styleId : TextStyleData.POPUP;
				styleId = ( DataUtils.validString( textData.styleId ) ) ? textData.styleId : textData.id;
				styleData = super.shellApi.textManager.getStyleData( styleFamily, styleId);
				if( styleData != null )
				{
					TextUtils.applyStyle(styleData, tf);
				}
			}
			
			// non-interactive elemenst finished loading
			assetLoadingComplete();
		}
		
		private function setButtonText( tf:TextField, id:String ):void
		{
			var buttonData:ButtonData;
			var styleData:TextStyleData;
			var i:int;
			for (i = 0; i < _buttonData.length; i++) 
			{
				buttonData = _buttonData[i]
				if( buttonData.id == BTN_BUY )
				{
					// apply label with style
					styleData = super.shellApi.textManager.getStyleData( TextStyleData.POPUP, buttonData.styleId );
					if( styleData != null )
					{
						TextUtils.applyStyle(styleData, tf);
					}
				}
			}
		}
		
		
		private const ASSET_PATH:String = "ui/popups/island_blocker.swf";
		private const DATA_FILE:String = "blocker.xml";
		
		// parameter ids : Text
		private const TITLE:String 				= "title";
		private const DESCRIPTION:String 		= "description";
		private const PUBLIC_ACCESS:String 		= "public_access";
		
		// button ids
		private const BTN_BUY:String 		= "buy";
		private const BTN_MEMBER:String 	= "membership";
		
		private var _content:MovieClip;
		
		private var _videoId:String;	// Defined in blocker.xml; = "fUyZyo3vvaU";
		private var _videoRect:Rectangle = new Rectangle(-196,-66.5,400,225);
		private var _youTubePlayer:PoptropicaYouTubePlayer;
		
		private var _currentElement:int = 0;	// used as part of loading process
		private var _assetsData:Vector.<AssetData> = new Vector.<AssetData>;
		private var _buttonData:Vector.<ButtonData> = new Vector.<ButtonData>;
		private var _textData:Vector.<TextData> = new Vector.<TextData>;
	}
}