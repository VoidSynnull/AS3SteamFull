package game.components.ui {

	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import game.data.display.BitmapWrapper;
	import game.data.ui.card.CardItemData;
	import game.ui.elements.MultiStateToggleButton;
	import game.util.DisplayUtils;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class CardItem extends Component
	{

		public function CardItem()
		{
			loadComplete = new Signal();
			buttonPress = new Signal();
			valueUpdate = new Signal();
			cardReady = new Signal();
		}

		public var disableButtons:Boolean = false;
		public var loadComplete:Signal;
		public var cardReady:Signal;
		public var buttonPress:Signal;
		public var valueUpdate:Signal;

		// card data
		public var cardData:CardItemData;					// for use with standard cards

		// displays
		public var spriteHolder:Sprite;
		public var spriteIsPlaceholder:Boolean = true;
		public var radioButtonHolder:Sprite;
		public var bitmapWrapper:BitmapWrapper;
		public var bitmapData:BitmapData;
		public var membersOnly:Sprite;

		// info
		public var bounds:Rectangle;		// size of the card
		public var itemId:String;			// id, for custom and store types id show already have the item prefix (e.g. item3010, item2050 )
		public var itemIdNoPrefix:String;	// id without prefix, which currently is only 'item'
		public var listIndex:int;			// when in a list, it's index
		public var pathPrefix:String;

		private var _value:*;					// used to store a single value, can be used for different values ( radio button number, tribe, label, etc. )
		public function get value():*	{ return _value; }
		public function set value( value:* ):void
		{
			if( _value != value )
			{
				_value = value;
				valueUpdate.dispatch( _value );
			}
		}

		// loading, flags used to determine load behavior
		public var isLoading:Boolean = false;
		public var loadBase:Boolean = false;
		public var displayLoaded:Boolean = false;
		public var currentElement:int = 0;	// used as part of loading process
		public var bitmapHolder:Sprite;		// used as part of loading process, container for portion of card dispaly that can be bitmapped

		// buttons
		public var radioButtons:Vector.<MultiStateToggleButton>;
		public var currentRadioBtnValue:* // Holds the current value selected by the radio buttons

		/**
		 * creates a duplicate CardItem, cloning variables
		 */
		public static function instanceFromIntializer(spec:Object):CardItem
		{
			return Utils.overlayObjectProperties(spec, new CardItem()) as CardItem;
		}

		/**
		 * Create or empty spriteHolder, depending on whether it has been instantiated or not
		 */
		public function resetSpriteHolder():void
		{
			displayLoaded = false;

			if( !spriteHolder){
				spriteHolder = new Sprite();
				bitmapHolder = new Sprite();
				spriteHolder.addChild( bitmapHolder );
			} else {
				DisplayUtils.removeAllChildren( spriteHolder );
			}
		}

		/**
		 * Create or empty spriteHolder, depending on whether it has been instantiated or not
		 */
		public function replaceSpriteHolder( nextHolder:Sprite ):void
		{
			if( !spriteHolder){
				spriteHolder = nextHolder;
			} else {
				DisplayUtils.swap( nextHolder, spriteHolder );
			}
		}

		/**
		 * Add interactive button to card
		 */
		public function addRadioButton( button:MultiStateToggleButton ):void
		{
			if( !radioButtons ){
				radioButtons = new Vector.<MultiStateToggleButton>();
			}
			radioButtons.push( button );
		}

		/**
		 * Add interactive button to card
		 */
		public function selectRadioButton( radioButton:MultiStateToggleButton ):void
		{
			if( radioButtons ) {
				for (var i:int = 0; i < radioButtons.length; i++) {

					if( radioButtons[i] == radioButton ){
						radioButton.selected = true;
					}else{
						radioButtons[i].selected = false;
					}

				}
			}
		}

		/**
		 * Clear Signals that have external listeners
		 */
		public function removeExternalListeners():void
		{
			valueUpdate.removeAll();
		}

		public function manualDestroy():void
		{
			value = null;
			currentRadioBtnValue = null;
			cardData = null;
			bounds = null;
			radioButtonHolder = null;
			spriteHolder = null;

			if( bitmapData )
			{
				bitmapData.dispose();
				bitmapData = null;
			}

			if( bitmapWrapper )
			{
				bitmapWrapper.destroy();
				bitmapWrapper = null;
			}

			if( radioButtons )
			{
				radioButtons.length = 0;
				radioButtons = null
			}

			if(loadComplete)
			{
				loadComplete.removeAll();
				loadComplete = null;
			}
			if(buttonPress)
			{
				buttonPress.removeAll();
				buttonPress = null;
			}
			if(valueUpdate)
			{
				valueUpdate.removeAll();
				valueUpdate = null;
			}
			
			if(cardReady)
			{
				cardReady.removeAll();
				cardReady = null;
			}

			super.destroy();
		}
	}
}
