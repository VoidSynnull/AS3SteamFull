package game.data.ui {
	import flash.text.TextFormat;

/**
* ButtonSpec formalizes the set of configuration data associated with a Poptropica button.
* It is a dynamic class which can accept new properties on the fly if necessary. Better
* you should work out new instance properties with the author than reserving cool new features
* for your sole use.
* @author Rich Martin
*/
public dynamic class ButtonSpec {

	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import engine.group.Group;
	import game.util.Utils;

	/**
	* Returns an instance populated with set of properties of your choosing.
	*
	* @example The following code creates a new ButtonSpec with two properties specified
	*
	*	<listing version="3.0">
	*
	*	var myBS:ButtonSpec = ButtonSpec.instanceFromInitializer(
	*		{
	*			displayObjectContainer:	new Sprite(),
	*			pressAction:	shellApi.soundManager.playStandardClick
	*		}
	*	);
	*
	*	</listing>
	*/
	public static function instanceFromInitializer(spec:Object):ButtonSpec {
		return Utils.overlayObjectProperties(spec, new ButtonSpec()) as ButtonSpec;
	}

	private var _displayObjectContainer:DisplayObjectContainer = null;
	private var _position:Point = null;
	private var _container:DisplayObjectContainer = null;
	private var _parentGroup:Group = null;
	private var _label:String = null;
	private var _format:TextFormat = null;
	private var _color:Number = NaN;
	private var _interactions:Array = null;
	private var _clickHandler:Function = null;
	private var _pressAction:Function = null;
	private var _selectedPressAction:Function = null;
	private var _bitmap:Boolean = false;
	private var _bitmapScale:Number = 1;
	private var _cursorType:String = "";
	private var _isStatic:Boolean = true;
	
	public function ButtonSpec() {
	}

	/**
	 * The <code>DisplayObjectContainer</code> which provides the visual asset for this button 
	 * @return 
	 * 
	 */	
	public function get displayObjectContainer():DisplayObjectContainer {	return _displayObjectContainer;	}
	/**
	 *  The <code>DisplayObjectContainer</code> which provides the visual asset for this button 
	 * @return 
	 * 
	 */	
	public function get displayObject():DisplayObjectContainer {			return _displayObjectContainer;	}
	/**
	 * @private
	 */	
	public function set displayObject(newDisplayObject:DisplayObjectContainer):void {
		_displayObjectContainer = newDisplayObject;
	}
	/**
	 * @private
	 */	
	public function set displayObjectContainer(newDisplayObject:DisplayObjectContainer):void {
		_displayObjectContainer = newDisplayObject;
	}

	/**
	 * The <code>Point</code> which provides the visual asset with location data. 
	 * @return 
	 * 
	 */	
	public function get position():Point {	return _position; }
	/**
	 * @private
	 */	
	public function set position(newPosition:Point):void {
		_position = newPosition;
	}

	/**
	 * The <code>DisplayObjectContainer</code> which should enclose the visual asset of this <code>StandardButton</code>.
	 * In other words, its superview. Note that <code>ButtonCreator</code> has a create function for <code>BasicButtons</code>
	 * which cannot set the parentage in this fashion, it can only establish a Group parent.
	 * @see game.creators.ui.ButtonCreator::create
	 * 
	 */	
	public function get container():DisplayObjectContainer {	return _container; }
	/**
	 * @private
	 */	
	public function set container(newContainer:DisplayObjectContainer):void {
		_container = newContainer;
	}

	/**
	 * The <code>Group</code> to which this button should be added. 
	 * @return 
	 * 
	 */	
	public function get parentGroup():Group {	return _parentGroup; }
	/**
	 * @private
	 */	
	public function set parentGroup(newGroup:Group):void {
		_parentGroup = newGroup;
	}

	/**
	 * The text which should appear on the button.
	 * @return 
	 * 
	 */	
	public function get label():String {	return _label; }
	/**
	 * @private
	 */	
	public function set label(newLabel:String):void {
		_label = newLabel;
	}
	
	/**
	 * The format that should be used for text.
	 * @return 
	 * 
	 */	
	public function get format():TextFormat {	return _format; }
	/**
	 * @private
	 */	
	public function set format(newFormat:TextFormat):void {
		_format = newFormat;
	}

	/**
	 * The <code>Array</code> of IDs corresponding to the <code>Signal</code>
	 * types which will be created for this button. 
	 * @return 
	 * @see engine.creators.InteractionCreator
	 */	
	public function get interactions():Array {	return _interactions; }
	/**
	 * @private
	 */	
	public function set interactions(newInteractions:Array):void {
		_interactions = newInteractions;
	}

	/**
	 * The <code>Function</code> which will be called automatically
	 * when the button receives a <code>CLICK NativeSignal</code>.
	 * Note that some <code>StandardButtons</code> are invoking this
	 * handler when they receive a <code>MOUSE_UP</code>.
	 * @return 
	 * 
	 */	
	public function get clickHandler():Function {	return _clickHandler; }
	/**
	 * @private
	 */	
	public function set clickHandler(newClickHandler:Function):void {
		_clickHandler = newClickHandler;
	}

	/**
	 * The <code>Function</code> which will be called automatically
	 * when the button receives a <code>MOUSE_DOWN NativeSignal</code>.
	 * @return 
	 * 
	 */	
	public function get pressAction():Function {	return _pressAction; }
	/**
	 * @private
	 */	
	public function set pressAction(newPressAction:Function):void {
		_pressAction = newPressAction;
	}

	/**
	 * The <code>Function</code> which will be called automatically
	 * when this <code>MultiStateToggleButton</code> receives a <code>MOUSE_DOWN NativeSignal</code>
	 * while its <code>selected</code> property is <code>TRUE</code>.
	 * @return 
	 * 
	 */	
	public function get selectedPressAction():Function {	return _selectedPressAction; }
	/**
	 * @private
	 */	
	public function set selectedPressAction(newSelectedPressAction:Function):void {
		_selectedPressAction = newSelectedPressAction;
	}
	
	/**
	 * Whether the button's <code>MovieClip</code> will be converted to a bitmap.
	 * Currently only works for Entity-based buttons.
	 * @return 
	 */	
	public function get bitmap():Boolean {	return _bitmap; }
	/**
	 * @private
	 */	
	public function set bitmap(value:Boolean):void {
		_bitmap = value;
	}
	
	/**
	 * Scale to use when converting to bitmap, only used if bitmap is set true.
	 * Currently only works for Entity-based buttons.
	 * @return 
	 */	
	public function get bitmapScale():Number {	return _bitmapScale; }
	/**
	 * @private
	 */	
	public function set bitmapScale(value:Number):void {
		_bitmapScale = value;
	}
	
	/**
	 * Whether the button's will be moved, for used with <code>Entity</code> buttons only.  
	 * If <code>TRUE</code> then <code>Spatial</code> is not linked to <code>Display</code>.
	 * If the button will move, then a value of <code>FALSE</code> shoudl be set.
	 * Currently only works for Entity-based buttons.
	 * @return 
	 */	
	public function get isStatic():Boolean {	return _isStatic; }
	/**
	 * @private
	 */	
	public function set isStatic(value:Boolean):void {
		_isStatic = value;
	}
	
	/**
	 * The type of cursor that will be displayed when input is over the button.
	 * Possible types can be accessed from  <code>ToolTipType</code>.
	 * <code>ToolTipType.CLICK</code> is the standard type.
	 * @return 
	 */	
	public function get cursorType():String { return _cursorType; }
	public function set cursorType(value:String):void {
		_cursorType = value;
	}

}

}
