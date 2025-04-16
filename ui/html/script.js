// Script para la interfaz del Sistema Avanzado de Ban
$(function() {
    // Variables
    let activeBans = [];
    
    // Mostrar/ocultar la interfaz
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.type === 'toggleUI') {
            if (data.state) {
                $('body').fadeIn(300);
            } else {
                $('body').fadeOut(300);
            }
        } else if (data.type === 'updateBans') {
            activeBans = data.bans;
            updateBanTable();
        } else if (data.type === 'banResult') {
            showResult('#ban-result', data.success, 
                data.success ? 'Jugador baneado exitosamente.' : 'Error al banear al jugador.');
        } else if (data.type === 'unbanResult') {
            showResult('#ban-result', data.success, 
                data.success ? 'Jugador desbaneado exitosamente.' : 'Error al desbanear al jugador.');
        }
    });
    
    // Cambiar entre pestañas
    $('.tab-btn').click(function() {
        $('.tab-btn').removeClass('active');
        $(this).addClass('active');
        
        const tabId = $(this).data('tab');
        $('.tab-pane').removeClass('active');
        $('#' + tabId).addClass('active');
    });
    
    // Cerrar la interfaz
    $('#close-btn').click(function() {
        $.post('https://str_bansystem/closeUI', JSON.stringify({}));
    });
    
    // Enviar formulario de ban
    $('#ban-form').submit(function(e) {
        e.preventDefault();
        
        const playerId = $('#player-id').val();
        const reason = $('#ban-reason').val();
        const duration = $('#ban-duration').val();
        
        if (!playerId || !reason) {
            showResult('#ban-result', false, 'Por favor completa todos los campos.');
            return;
        }
        
        const banData = {
            targetId: parseInt(playerId),
            reason: reason,
            duration: parseInt(duration)
        };
        
        $.post('https://str_bansystem/banPlayer', JSON.stringify(banData));
    });
    
    // Buscar jugador
    $('#search-btn').click(function() {
        const searchTerm = $('#search-term').val();
        
        if (!searchTerm) {
            return;
        }
        
        $.post('https://str_bansystem/searchPlayer', JSON.stringify({term: searchTerm}), function(results) {
            updateSearchResults(results);
        });
    });
    
    // Actualizar tabla de bans
    function updateBanTable() {
        const $tbody = $('#bans-table tbody');
        $tbody.empty();
        
        if (activeBans.length === 0) {
            $tbody.append('<tr><td colspan="7" style="text-align: center;">No hay bans registrados.</td></tr>');
            return;
        }
        
        activeBans.forEach(ban => {
            const row = createBanRow(ban);
            $tbody.append(row);
        });
        
        // Añadir eventos para los botones de desbanear
        $('.unban-btn').click(function() {
            const banId = $(this).data('id');
            $.post('https://str_bansystem/unbanPlayer', JSON.stringify({banId: banId}));
        });
    }
    
    // Actualizar resultados de búsqueda
    function updateSearchResults(results) {
        const $tbody = $('#search-results-table tbody');
        $tbody.empty();
        
        if (results.length === 0) {
            $tbody.append('<tr><td colspan="7" style="text-align: center;">No se encontraron resultados.</td></tr>');
            return;
        }
        
        results.forEach(ban => {
            const row = createBanRow(ban);
            $tbody.append(row);
        });
        
        // Añadir eventos para los botones de desbanear
        $('.unban-btn').click(function() {
            const banId = $(this).data('id');
            $.post('https://str_bansystem/unbanPlayer', JSON.stringify({banId: banId}));
        });
    }
    
    // Crear fila para un ban
    function createBanRow(ban) {
        const date = new Date(ban.timestamp * 1000);
        const formattedDate = `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()} ${date.getHours()}:${date.getMinutes()}`;
        
        const duration = ban.duration > 0 ? `${ban.duration} días` : 'Permanente';
        
        return `
            <tr>
                <td>${ban.id}</td>
                <td>${ban.targetName}</td>
                <td>${ban.adminName}</td>
                <td>${ban.reason}</td>
                <td>${duration}</td>
                <td>${formattedDate}</td>
                <td><button class="btn-danger unban-btn" data-id="${ban.id}">Desbanear</button></td>
            </tr>
        `;
    }
    
    // Mostrar mensaje de resultado
    function showResult(selector, success, message) {
        const $result = $(selector);
        $result.removeClass('success error').addClass(success ? 'success' : 'error');
        $result.text(message);
        $result.fadeIn(300);
        
        // Ocultar después de 3 segundos
        setTimeout(function() {
            $result.fadeOut(300);
        }, 3000);
    }
    });