classdef txrx < zynq_RS232.base
    %Tx/Rx RS232 message
    %   Transfer and Receive messages from the network
    %   Include termination characters in message length
    properties (Nontunable)        
        % Timeout
        %
        % The timeout for receiving data
        %
        % 0 = non-blocking
        % Inf = Blocking
        % Other values = timeout in seconds
        Timeout = 0; %- always running non-blocking
        BaudRate = 119200;
        MessageLength = int32(1);
    end
       
    properties (Hidden, Access = protected, Dependent)
        privTimeout;
    end
    
   
    methods
        function val = get.privTimeout(obj)
            if obj.Timeout == Inf
                val = -1.0;
            else
                val = double(obj.Timeout);
            end
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj)
            openRS232(obj);
        end
        
        function [rx_msg status] = stepImpl(obj,tx_msg,tx_len)
            %initializing variables            
            if coder.target('Rtw')
                status = int32(-1);
                rx_msg_buf = coder.nullcopy(zeros(200,1, 'uint8'));
                status = coder.ceval('read', obj.uart_port,coder.wref(...
                    rx_msg_buf), obj.MessageLength);
                rx_msg = coder.nullcopy(zeros(200,1,'uint8'));
                if status > 0
                    rx_msg(1:status) = rx_msg_buf(1:status);
                end                     
                %coder.ceval('send_uart_rs232', obj.uart_port,...
                %    tx_msg,uint8(numel(tx_msg)));
            else 
                rx_msg = uint8(zeros(obj.MessageLength,1)); 
                status = -1;
            end
        end
        
        function icon = getIconImpl(obj) %#ok<MANU>
            icon = sprintf('Zynq RS232');
        end
        
%         function flag = isInactivePropertyImpl(obj, prop)
%             flag = false;
%             switch (prop)
%                 case {'Baud Rate'}
%                     flag = ~obj.FilterEnable;
%             end
%         end
    end
    
    %% External Dependency Methods
    methods (Static)
        function bName = getDescriptiveName(~)
            % getDescriptiveName get the name of the block
            % Internal function for Simulink Block generation
            bName = 'RS232 Tx/Rx';
        end
    end
    
    methods (Hidden, Static, Access = protected)
        function groups = getPropertyGroupsImpl
            groups = matlab.system.display.Section(...
                'PropertyList',{'BaudRate', 'MessageLength'});
        end
    end
    
    
    %% Propagation Methods
    methods (Hidden, Access = protected)
        
         %% Inputs validation
        
        function validatePropertiesImpl(~)
        end
        
        %% Initializers / Value Getters
        function N = getNumOutputsImpl(~)
            % Specify number of System Outputs
            N = 2;
        end
        
        function [rx_msg status] = getOutputSizeImpl(~)
            rx_msg = 200;
            status = 1;
        end
        
        function [rx_msg status]= isOutputFixedSizeImpl(~)

            rx_msg = true;
            status = true; 

        end
        
        function [rx_msg status] = getOutputDataTypeImpl(~)

            rx_msg = 'uint8';
            status = 'int32';

        end
        
        function [rx_msg status] =  getOutputNamesImpl(~)

            rx_msg = 'Rx Data';
            status = 'Data length';

        end
        
        function [rx_msg status] = isOutputComplexImpl(~)
            rx_msg = false;
            status = false;
        end
        
        function N = getNumInputsImpl(obj)
            % Specify number of System inputs
            N = 2;
        end
       
        function [tx_msg, tx_len] = getInputNamesImpl(obj)
            tx_msg = 'Tx Data';
            tx_len = 'Tx Length';
        end
    end
end

